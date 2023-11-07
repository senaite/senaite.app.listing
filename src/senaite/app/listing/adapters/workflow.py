# -*- coding: utf-8 -*-

from bika.lims import api
from bika.lims.workflow import doActionFor
from Products.CMFCore.WorkflowCore import WorkflowException
from senaite.app.listing import logger
from senaite.app.listing import senaiteMessageFactory as _
from senaite.app.listing.interfaces import IListingWorkflowTransition
from ZODB.POSException import ConflictError
from zope.interface import implementer


@implementer(IListingWorkflowTransition)
class ListingWorkflowTransition(object):
    """Adapter to execute workflow transitions in listings
    """
    def __init__(self, view, context, request):
        self.view = view
        self.context = context
        self.request = request
        self.error = {}

    @property
    def failed(self):
        """Flag to indicate if the transition failed
        """
        if self.error:
            return True
        return False

    def get_error(self):
        """Return the error message
        """
        return self.error.get("message")

    def get_redirect_url(self):
        """Return redirect URL
        """
        return ""

    def get_uids(self):
        """Return the uids affected by the transition
        """
        return [api.get_uid(self.context)]

    def do_transition(self, transition):
        """Execute the workflow transition
        """
        obj = self.context
        oid = api.get_id(obj)

        try:
            # https://github.com/senaite/senaite.app.listing/pull/138
            # obj = api.do_transition_for(obj, transition)
            # obj.reindexObject()
            succeed, message = doActionFor(obj, transition)
            if not succeed:
                raise WorkflowException(message)
        except ConflictError:
            self.error["message"] = _(
                "A database conflict error occurred during transition "
                "'{}' on '{}'. Please try again.".format(transition, oid))
        except (api.APIError, WorkflowException) as exc:
            # NOTE: We do not propagate back to the UI when the transition
            #       failed, because it is most of the time an expected
            #       side-effect. E.g. when an analysis with calculation
            #       dependencies is submitted, the dependent analyses are
            #       submitted as well. Therefore, if the current object is
            #       such a dependency, it might fail here.
            logger.warn(exc)
        except Exception as exc:
            self.error["message"] = _(
                "An unkown error occurred during transition '{}' on '{}': {}"
                .format(transition, oid, exc.message))
