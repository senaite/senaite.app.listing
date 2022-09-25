# -*- coding: utf-8 -*-

from bika.lims import senaiteMessageFactory as _
from plone.supermodel import model
from senaite.core.registry.schema import ISenaiteRegistry
from zope import schema


class IListingRegistry(ISenaiteRegistry):
    """Registry settings for listings
    """

    model.fieldset(
        "listings",
        label=_(u"Listings"),
        description=_("Configuration for listings"),
        fields=[
            "listing_enable_ajax_transitions",
            "listing_ajax_transitions_blacklist",
        ],
    )

    listing_enable_ajax_transitions = schema.Bool(
        title=_("Enable Ajax Transitions"),
        description=_(
            "Enable ajax form submission for transition buttons (Experimental)"
        ),
        default=False,
        required=False,
    )

    listing_ajax_transitions_blacklist = schema.List(
        title=_("Ajax Transitions Blacklist"),
        description=_(
            "Always disable ajax form submissions for the listed types/views"
        ),
        value_type=schema.ASCIILine(),
        default=[
            "AnalysisServices",  # copy action not working in Ajax mode
            "Client",  # All WF actions redirect back to samples listing
            "Samples",  # all transition buttons are redirects
            "WorksheetFolder",  # delete action not working in Ajax mode
            "published_results",  # download action not working in Ajax mode
            "reports_listing",  # download action not working in Ajax mode
            "add_analyses",  # reload after assigning analyses in worksheets
            "manage_analyses",  # reload after adding analyses in samples
        ],
        required=False,
    )
