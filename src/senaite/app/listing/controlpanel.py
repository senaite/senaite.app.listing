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
            "analyses",  # reload after adding analyses in samples
        ],
        required=False,
    )
