# -*- coding: utf-8 -*-
#
# This file is part of SENAITE.CORE.SUPERMODEL
#
# Copyright 2018 by it's authors.

from zope.interface import Interface


class IListingView(Interface):
    """Senaite Core Listing View
    """


class IAjaxListingView(Interface):
    """Senaite Core Ajax Listing View
    """


class IListingViewAdapter(Interface):
    """Marker that allows to modify the behavior of ListingView
    """

    def get_priority_order(self):
        """Returns an number that represents the order of priority of this
        adapter over other subscriber adapters that adapt same context and
        listing view. A lower value means more priority.
        """

    def before_render(self):
        """Before render hook
        """

    def folder_item(self, obj, item, index):
        """folder_item hook
        """
