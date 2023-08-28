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
# Copyright 2018-2023 by it's authors.
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
            "listing_active_ajax_transitions",
        ],
    )

    listing_enable_ajax_transitions = schema.Bool(
        title=_("Enable Ajax Transitions"),
        description=_("Enable sequential ajax workflow transitions"),
        default=False,
        required=False,
    )

    listing_active_ajax_transitions = schema.List(
        title=_("Active ajax transitions"),
        description=_("Transitions that are processed sequentially via ajax"),
        value_type=schema.ASCIILine(),
        default=[
            "receive",
            "submit",
            "verify",
            "cancel",
            "reinstate",
            "deactivate",
            "activate",
        ],
        required=False,
    )
