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
