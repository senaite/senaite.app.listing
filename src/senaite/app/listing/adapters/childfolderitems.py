# -*- coding: utf-8 -*-

from bika.lims import api
from senaite.app.listing.interfaces import IChildFolderItems
from zope.interface import implementer
from senaite.app.listing import logger


@implementer(IChildFolderItems)
class ChildFolderItems(object):
    """Multi adapter to get the child folderitems
    """

    def __init__(self, view, context, request):
        self.view = view
        self.context = context
        self.request = request

    def get_query(self, parent_uid, child_uids):
        if child_uids:
            return {"UID": child_uids}
        parent = api.get_object_by_uid(parent_uid)
        return {
            "path": {
                "query": api.get_path(parent),
                "depth": 1,
            }
        }

    def get_children(self, parent_uid, child_uids=None):
        """Return child folderitems
        """
        query = self.get_query(parent_uid, child_uids)
        logger.info("Child Query: {}".format(repr(query)))
        self.view.contentFilter = query
        children = self.view.get_folderitems()
        return children
