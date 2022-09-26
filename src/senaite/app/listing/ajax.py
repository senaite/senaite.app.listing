# -*- coding: utf-8 -*-
#
# This file is part of SENAITE.APP.LISTING.
#
# SENAITE.APP.LISTING is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by the Free
# Software Foundation, version 2.
#
# This program is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
# FOR A PARTICULAR PURPOSE. See the GNU General Public License for more
# details.
#
# You should have received a copy of the GNU General Public License along with
# this program; if not, write to the Free Software Foundation, Inc., 51
# Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
#
# Copyright 2018-2022 by it's authors.
# Some rights reserved, see README and LICENSE.

import inspect
import json
from functools import cmp_to_key

import six
from six.moves.urllib.parse import urlencode

from bika.lims import api
from bika.lims.browser import BrowserView
from plone.memoize import view
from Products.Archetypes.event import ObjectEditedEvent
from Products.Five.browser.pagetemplatefile import ViewPageTemplateFile
from senaite.app.listing.decorators import inject_runtime
from senaite.app.listing.decorators import returns_safe_json
from senaite.app.listing.decorators import set_application_json_header
from senaite.app.listing.decorators import translate
from senaite.app.listing.interfaces import IAjaxListingView
from senaite.app.listing.interfaces import IChildFolderItems
from senaite.core.decorators import readonly_transaction
from senaite.core.interfaces import IDataManager
from senaite.core.p3compat import cmp
from senaite.core.registry import get_registry_record
from zope import event
from zope.component import getMultiAdapter
from zope.component import queryAdapter
from zope.interface import implementer
from zope.lifecycleevent import modified
from zope.publisher.interfaces import IPublishTraverse


@implementer(IAjaxListingView, IPublishTraverse)
class AjaxListingView(BrowserView):
    """Mixin Class for the ajax enabled listing table

    The main purpose of this class is to provide a JSON API endpoint for the
    ReactJS based listing table.
    """
    contents_table_template = ViewPageTemplateFile(
        "templates/contents_table.pt")
    contents_table_template_view = ViewPageTemplateFile(
        "templates/contents_table_view.pt")

    def __init__(self, context, request):
        super(AjaxListingView, self).__init__(context, request)
        self.traverse_subpath = []

    def ajax_contents_table(self, *args, **kwargs):
        """Render the ReactJS enabled contents table template
        """
        return self.contents_table_template()

    def contents_table_view(self, *args, **kwargs):
        """Render contents table in 'view' mode
        """
        return self.contents_table_template_view()

    def publishTraverse(self, request, name):
        """Called before __call__ for each path name and allows to dispatch
        subpaths to methods
        """
        self.traverse_subpath.append(name)
        return self

    def handle_subpath(self, prefix="ajax_"):
        """Dispatch the subpath to a method prefixed with the given prefix

        N.B. Only the first subpath element will be dispatched to a method and
             the rest will be passed as arguments to this method
        """
        if len(self.traverse_subpath) < 1:
            return {}

        # check if the method exists
        func_arg = self.traverse_subpath[0]
        func_name = "{}{}".format(prefix, func_arg)
        func = getattr(self, func_name, None)
        if func is None:
            raise NameError("Invalid function name")

        # Additional provided path segments after the function name are handled
        # as positional arguments
        args = self.traverse_subpath[1:]

        # check mandatory arguments
        func_sig = inspect.getargspec(func)
        # positional arguments after `self` argument
        required_args = func_sig.args[1:]

        if len(args) < len(required_args):
            raise ValueError("Wrong signature, please use '{}/{}'"
                             .format(func_arg, "/".join(required_args)))
        return func(*args)

    def get_json(self, encoding="utf8"):
        """Extracts the JSON from the request
        """
        body = self.request.get("BODY", "{}")

        def encode_hook(pairs):
            """This hook is called for dicitionaries on JSON deserialization

            It is used to encode unicode strings with the given encoding,
            because ZCatalogs have sometimes issues with unicode queries.
            """
            new_pairs = []
            for key, value in pairs.iteritems():
                # Encode the key
                if isinstance(key, six.string_types):
                    key = key.encode(encoding)
                # Encode the value
                if isinstance(value, six.string_types):
                    value = value.encode(encoding)
                new_pairs.append((key, value))
            return dict(new_pairs)

        return json.loads(body, object_hook=encode_hook)

    def json_message(self, message, status=500, level="error", **kw):
        """Set a JSON message object and a status to the response
        """
        self.request.response.setStatus(status)
        result = {
            "message": message,
            "status": status,
            "level": level,
        }
        result.update(kw)
        return result

    @view.memoize
    @translate
    def get_columns(self):
        """Returns the `columns` dictionary of the view
        """
        return self.columns

    @translate
    def get_review_states(self):
        """Returns the `review_states` list of the view
        """
        return self.review_states

    def to_form_data(self, data):
        """Prefix all data keys with `self.form_id`

        This is needed to inject the POST Body to the request form data, so
        that the `BikaListingView.folderitems` finds them.
        """
        out = {}
        for key, value in data.iteritems():
            if not key.startswith(self.form_id):
                k = "{}_{}".format(self.form_id, key)
            out[k] = value
        return out

    def get_api_url(self):
        """Calculate the API URL of this view
        """
        url = self.context.absolute_url()
        view_name = self.__name__
        return "{}/{}".format(url, view_name)

    def get_transitions_for(self, obj):
        """Get the allowed transitions for the given object
        """
        return api.get_transitions_for(obj)

    def get_allowed_transitions_for(self, uids):
        """Retrieves all transitions from the given UIDs and calculate the
        ones which have all in common (intersection).
        """

        # Handle empty list of objects
        if not uids:
            return []

        # allowed transitions
        transitions = []

        # allowed transitions of the current workflow
        allowed_transitions = self.review_state.get("transitions", [])
        allowed_transition_ids = map(
            lambda t: t.get("id"), allowed_transitions)

        # internal mapping of transition id -> transition
        transitions_by_tid = {}

        # get the custom transitions of the current review_state
        custom_transitions = self.review_state.get("custom_transitions", [])

        # N.B. we use set() here to handle dupes in the views gracefully
        custom_tids = set()
        for transition in custom_transitions:
            tid = transition.get("id")
            custom_tids.add(tid)
            transitions_by_tid[tid] = transition

        # transition ids all objects have in common
        common_tids = set()

        for uid in uids:
            # TODO: Research how to avoid the object wakeup here
            obj = api.get_object_by_uid(uid)
            obj_transitions = self.get_transitions_for(obj)
            # skip objects w/o transitions, e.g. retracted/rejected analyses
            if not obj_transitions:
                continue
            tids = []
            for transition in obj_transitions:
                tid = transition.get("id")
                if allowed_transition_ids:
                    if tid not in allowed_transition_ids:
                        continue
                    tids.append(tid)
                else:
                    # no restrictions by the selected review_state
                    tids.append(tid)
                transitions_by_tid[tid] = transition

            if not common_tids:
                common_tids = set(tids)

            common_tids = common_tids.intersection(tids)

        # union the common and custom transitions
        all_transition_ids = common_tids.union(custom_tids)

        def sort_transitions(a, b):
            default_weights = {
                "invalidate": 100,
                "retract": 90,
                "reject": 90,
                "cancel": 80,
                "deactivate": 70,
                "unassign": 70,
                "publish": 60,
                "republish": 50,
                "prepublish": 50,
                "partition": 40,
                "assign": 30,
                "receive": 20,
                "submit": 10,
            }
            w1 = transitions_by_tid[a].get(
                "weight", default_weights.get(a, 0))
            w2 = transitions_by_tid[b].get(
                "weight", default_weights.get(b, 0))
            return cmp(w1, w2)

        for tid in sorted(all_transition_ids, key=cmp_to_key(sort_transitions)):
            transition = transitions_by_tid.get(tid)
            transitions.append(transition)

        return transitions

    def get_category_uid(self, brain_or_object, accessor="getCategoryUID"):
        """Get the category UID from the brain or object

        This will be used to speed up the listing by categories
        """
        attr = getattr(brain_or_object, accessor, None)
        if attr is None:
            return ""
        if callable(attr):
            return attr()
        return attr

    @returns_safe_json
    def ajax_review_states(self):
        """Returns the `review_states` list of the view as JSON
        """
        return self.get_review_states()

    @returns_safe_json
    def ajax_columns(self):
        """Returns the `columns` dictionary of the view as JSON
        """
        return self.get_columns()

    @returns_safe_json
    def ajax_show_column_toggles(self):
        """Returns the boolean value of the show_column_toggles attribute
        """
        return self.show_column_toggles

    @view.memoize
    @returns_safe_json
    def ajax_transitions_enabled(self):
        """Returns wether transitions should be submitted via ajax
        """
        # return immediately if disabled globally
        enabled = get_registry_record("listing_enable_ajax_transitions", False)
        if not enabled:
            return False
        blist = get_registry_record("listing_ajax_transitions_blacklist", [])
        # return immediately if the portal type is blacklisted
        if api.get_portal_type(self.context) in blist:
            return False
        # return immediately if the current view name is blacklisted
        if self.__name__ in blist:
            return False
        # return immediately if the current view disabled ajax transitions
        if self.enable_ajax_transitions is False:
            return False
        return True

    @translate
    def get_folderitems(self):
        """This method calls the folderitems method
        """
        # workaround for `pagesize` handling
        pagesize = self.get_pagesize()
        self.pagesize = pagesize

        # get the folderitems
        self.update()
        self.before_render()

        return self.folderitems()

    def get_selected_uids(self, folderitems, uids_to_keep=None):
        """Lookup selected UIDs from the folderitems
        """
        selected_uids = []
        if uids_to_keep:
            selected_uids = uids_to_keep

        for folderitem in folderitems:
            uid = folderitem.get("uid")
            if uid in selected_uids:
                continue
            if folderitem.get("selected", False):
                selected_uids.append(folderitem.get("uid"))
        return selected_uids

    def get_listing_config(self):
        """Get the configuration settings of the current listing view
        """

        config = {
            "form_id": self.form_id,
            "form_name": self.get_form_name(),
            "review_states": self.get_review_states(),
            "columns": self.get_columns(),
            "content_filter": self.contentFilter,
            "allow_edit": self.allow_edit,
            "api_url": self.get_api_url(),
            "catalog": self.catalog,
            "catalog_indexes": self.get_catalog_indexes(),
            "catalog_columns": self.get_metadata_columns(),
            "categories": self.categories,
            "expand_all_categories": self.expand_all_categories,
            "limit_from": self.limit_from,
            "pagesize": self.pagesize,
            "post_action": self.getPOSTAction(),
            "review_state": self.review_state.get("id", "default"),
            "select_checkbox_name": self.select_checkbox_name,
            "show_categories": self.show_categories,
            "show_column_toggles": self.show_column_toggles,
            "show_more": self.show_more,
            "show_select_all_checkbox": self.show_select_all_checkbox,
            "show_select_column": self.show_select_column,
            "show_table_footer": self.show_table_footer,
            "show_workflow_action_buttons": self.show_workflow_action_buttons,
            "sort_on": self.get_sort_on(),
            "manual_sort_on": self.manual_sort_on,
            "sort_order": self.get_sort_order(),
            "sortable_columns": self.get_sortable_columns(),
            "show_search": self.show_search,
            "fetch_transitions_on_select": self.fetch_transitions_on_select,
            "view_context_state": api.get_workflow_status_of(self.context),
        }

        return config

    def get_sortable_columns(self):
        """Return sortable columns

        Sortable columns have either an index or a metadata column

        :returns: list of sortable columns
        """
        # filter out any columns which are explicitly set to False
        columns = filter(lambda item: item[1].get("sortable", True),
                         self.columns.items())
        return map(lambda item: item[0], columns)

    def set_field(self, obj, name, value):
        """Set the value

        :returns: List of updated/changed objects
        """

        # query the datamanager
        datamanager = queryAdapter(obj, interface=IDataManager)
        if datamanager is None:
            return []

        # set the value with the datamanager
        updated_objects = datamanager.set(name, value)

        # reindex the objects
        map(lambda obj: obj.reindexObject(), updated_objects)

        # notify that the objects were modified
        map(modified, updated_objects)

        return updated_objects

    @readonly_transaction
    @set_application_json_header
    @returns_safe_json
    @inject_runtime
    def ajax_folderitems(self):
        """Calls the `folderitems` method of the view and returns it as JSON

        1. Extract the HTTP POST payload from the request
        2. Convert the payload to HTTP form data and inject it to the request
        3. Call the `folderitems` method
        4. Prepare a data structure for the ReactJS listing app
        """

        # Get the HTTP POST JSON Payload
        payload = self.get_json()

        # Fake a HTTP GET request with parameters, so that the `bika_listing`
        # view handles them correctly.
        form_data = self.to_form_data(payload)

        # this serves `request.form.get` calls
        self.request.form.update(form_data)

        # this serves `request.get` calls
        self.request.other.update(form_data)

        # generate a query string from the form data
        query_string = urlencode(form_data)

        # get the folder items
        folderitems = self.get_folderitems()

        # Process selected UIDs and their allowed transitions
        uids_to_keep = payload.get("selected_uids")
        selected_uids = self.get_selected_uids(folderitems, uids_to_keep)
        selected_uids = filter(api.is_uid, selected_uids)
        transitions = self.get_allowed_transitions_for(selected_uids)

        # get the view config
        config = self.get_listing_config()

        # prepare the response object
        data = {
            "count": len(folderitems),
            "folderitems": folderitems,
            "query_string": query_string,
            "selected_uids": selected_uids,
            "total": self.total,
            "transitions": transitions,
        }

        # update the config
        data.update(config)

        return data

    @readonly_transaction
    @set_application_json_header
    @returns_safe_json
    @inject_runtime
    def ajax_transitions(self):
        """Returns a list of possible transitions
        """
        # Get the HTTP POST JSON Payload
        payload = self.get_json()

        # Get the selected UIDs
        uids = payload.get("selected_uids", [])

        # ----------------------------------8<---------------------------------
        # XXX Temporary (cut out as soon as possible)
        #
        # Some listings inject custom transitions before rendering the
        # folderitems, e.g. the worksheets folder listing view.
        # This can be removed as soon as all the relevant permission checks are
        # done on the object only and not by manual role checking in the view.

        # Fake a HTTP GET request with parameters, so that the `bika_listing`
        # view handles them correctly.
        form_data = self.to_form_data(payload)

        # this serves `request.form.get` calls
        self.request.form.update(form_data)

        # this serves `request.get` calls
        self.request.other.update(form_data)

        # Call the update and before_render hook, because these might modify
        # the allowed and custom transitions (and columns probably as well)
        self.update()
        self.before_render()
        # ----------------------------------8<---------------------------------

        # get the allowed transitions
        transitions = self.get_allowed_transitions_for(uids)

        # prepare the response object
        data = {
            "transitions": transitions,
        }

        return data

    @readonly_transaction
    @set_application_json_header
    @returns_safe_json
    @inject_runtime
    def ajax_get_children(self):
        """Get the children of a folderitem

        Required POST JSON Payload:

        :uid: UID of the parent folderitem
        """

        # Get the HTTP POST JSON Payload
        payload = self.get_json()

        # extract the parent UID
        parent_uid = payload.get("parent_uid")
        child_uids = payload.get("child_uids", [])

        # get the child folderitems adapter
        adapter = getMultiAdapter(
            (self, self.context, self.request), IChildFolderItems)
        # fetch the child folderitems from the adapter
        children = adapter.get_children(parent_uid, child_uids=child_uids)
        # ensure the children have a reference to the parent
        for child in children:
            child["parent"] = parent_uid
        # prepare the response object
        data = {
            "children": children
        }
        return data

    @readonly_transaction
    @set_application_json_header
    @returns_safe_json
    @inject_runtime
    def ajax_query_folderitems(self):
        """Get folderitems with a catalog query

        Required POST JSON Payload:

        :query: Catalog query to use
        :type query: dictionary
        """

        # Get the HTTP POST JSON Payload
        payload = self.get_json()

        # extract the catalog query
        query = payload.get("query", {})

        valid_catalog_indexes = self.get_catalog_indexes()

        # sanity check
        for key, value in query.iteritems():
            if key not in valid_catalog_indexes:
                return self.json_message(
                    "{} is not a valid catalog index".format(key), 400)

        # set the content filter
        self.contentFilter = query

        # get the folderitems
        folderitems = self.get_folderitems()

        # prepare the response object
        data = {
            "count": len(folderitems),
            "folderitems": folderitems,
        }

        return data

    @set_application_json_header
    @returns_safe_json
    @inject_runtime
    def ajax_set_fields(self):
        """Set multiple fields

        The POST Payload needs to provide the following data:

        :save_queue: A mapping of {UID: {fieldname: fieldvalue, ...}}
        """

        # Get the HTTP POST JSON Payload
        payload = self.get_json()

        required = ["save_queue"]
        if not all(map(lambda k: k in payload, required)):
            return self.json_message("Payload needs to provide the keys {}"
                                     .format(", ".join(required)), status=400)

        save_queue = payload.get("save_queue")

        updated_objects = set()
        for uid, data in save_queue.iteritems():
            # get the object
            obj = api.get_object_by_uid(uid)

            # update the fields
            for name, value in data.iteritems():
                updated_objects.update(self.set_field(obj, name, value))

        if not updated_objects:
            return self.json_message("Failed to set field of save queue '{}'"
                                     .format(save_queue), 500)

        # notify object edited
        map(self.notify_edited, updated_objects)

        # get the updated folderitems
        updated_uids = map(api.get_uid, updated_objects)
        self.contentFilter["UID"] = updated_uids
        folderitems = self.get_folderitems()

        # prepare the response object
        data = {
            "count": len(folderitems),
            "uids": updated_uids,
            "folderitems": folderitems,
        }

        return data

    @set_application_json_header
    @returns_safe_json
    @inject_runtime
    def ajax_on_change(self):
        """Callback for changes in the listing

        The POST Payload needs to provide the following data:
        """

        # Get the HTTP POST JSON Payload
        payload = self.get_json()

        required = ["handler", "data"]
        if not all(map(lambda k: k in payload, required)):
            return self.json_message("Payload needs to provide the keys {}"
                                     .format(", ".join(required)), status=400)

        handler = payload.get("handler")
        data = payload.get("data")

        method = getattr(self, handler, None)
        if method is None:
            return self.json_message("Method '{}' not defined in class '{}'"
                                     .format(handler, self.__class__.__name__),
                                     status=400)

        folderitems = method(**data)
        if not isinstance(folderitems, (dict, list)):
            return {}
        if isinstance(folderitems, dict):
            folderitems = [folderitems]

        # prepare the response object
        data = {
            "count": len(folderitems),
            "folderitems": folderitems,
        }

        return data

    def notify_edited(self, obj):
        """Notify object edited event
        """
        event.notify(ObjectEditedEvent(obj))
