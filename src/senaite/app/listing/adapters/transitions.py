# -*- coding: utf-8 -*-

from functools import cmp_to_key

from bika.lims import api
from senaite.app.listing.interfaces import IListingTransitions
from senaite.core.p3compat import cmp
from zope.interface import implementer

IGNORE_STATES_WITHOUT_TRANSITIONS = [
    "published",
    "rejected",
    "retracted",
]


@implementer(IListingTransitions)
class ListingTransitions(object):
    """Adapter to calculate all available transitions
    """
    def __init__(self, view, context, request):
        self.view = view
        self.context = context
        self.request = request
        self.default_transition_weights = self.get_default_transition_weights()
        # internal object cache
        self._object_cache = {}

    def get_default_transition_weights(self):
        """Return default transitions weights for sorting
        """
        return {
            "invalidate": 100,
            "retract": 90,
            "reject": 90,
            "remove": 90,
            "cancel": 80,
            "deactivate": 70,
            "unassign": 70,
            "close": 70,
            "publish": 60,
            "republish": 50,
            "prepublish": 50,
            "verify": 50,
            "partition": 40,
            "assign": 30,
            "receive": 20,
            "submit": 10,
        }

    def get_object_by_uid(self, uid):
        """Cached version to api.get_object_by_uid
        """
        if not api.is_uid(uid):
            return None
        if uid in self._object_cache:
            return self._object_cache[uid]
        self._object_cache[uid] = api.get_object_by_uid(uid, None)
        return self._object_cache[uid]

    def get_allowed_transition_ids(self, uids):
        """Get allowed transition IDs for the current workflow filter
        """
        allowed_transitions = self.view.review_state.get("transitions", [])
        allowed_transition_ids = map(
            lambda t: t.get("id"), allowed_transitions)
        return list(allowed_transition_ids)

    def get_transitions(self, uids):
        """Returns a sorted list of possible transitions
        """
        transitions = []
        transitions_by_tid = {}

        custom_transitions = self.get_custom_transitions(uids)
        workflow_transitions = self.get_workflow_transitions(uids)
        all_transitions = custom_transitions + workflow_transitions
        allowed_transition_ids = self.get_allowed_transition_ids(uids)

        # unify all allowed transitions by their ID
        for transition in all_transitions:
            tid = transition.get("id", "")
            # filter out disallowed transitions
            if allowed_transition_ids:
                if tid not in allowed_transition_ids:
                    continue
            transitions_by_tid[tid] = transition

        def sort_transitions(a, b):
            w1 = transitions_by_tid[a].get(
                "weight", self.default_transition_weights.get(a, 0))
            w2 = transitions_by_tid[b].get(
                "weight", self.default_transition_weights.get(b, 0))
            return cmp(w1, w2)

        # sort all possible transitions by their weights
        tids = transitions_by_tid.keys()
        for tid in sorted(tids, key=cmp_to_key(sort_transitions)):
            transition = transitions_by_tid.get(tid)
            transitions.append(transition)

        return transitions

    def get_workflow_transitions(self, uids):
        """Get workflow transitions for the given UIDs

        :param uids: UIDs of the selected items
        :returns: List of workflow transitions
        """
        # transition IDs all objects have in common
        common_tids = set()

        # internal mapping of transition id -> transition
        transitions_by_tid = {}

        for uid in uids:
            obj = self.get_object_by_uid(uid)
            transitions = api.get_transitions_for(obj)
            if not transitions:
                review_state = api.get_review_status(obj)
                # Skip/ignore some workflow states without further transitions
                # for usability purposes especially in Worksheets.
                # => This allows a user to select all Analyses and still be
                #    able to submit/verify those which allow these transitions.
                if review_state in IGNORE_STATES_WITHOUT_TRANSITIONS:
                    continue
                # no need to go any further, no shared transitions can exist
                common_tids.clear()
                break

            # collect all possible transitions for this object
            tids = []
            for transition in transitions:
                tid = transition.get("id")
                tids.append(tid)
                # remember the transition
                transitions_by_tid[tid] = transition

            if common_tids:
                # only keep transition IDs that are in common
                common_tids = common_tids.intersection(tids)
            else:
                common_tids = set(tids)

        # return all transitions that are in common
        transitions = map(lambda tid: transitions_by_tid.get(tid), common_tids)
        return list(transitions)

    def get_custom_transitions(self, uids):
        """Get custom transitions for the given UIDs

        :param uids: UIDs of the selected items
        :returns: List of custom transitions
        """
        return self.view.review_state.get("custom_transitions", [])
