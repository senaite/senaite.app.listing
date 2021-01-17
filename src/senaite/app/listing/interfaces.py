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
# Copyright 2018-2021 by it's authors.
# Some rights reserved, see README and LICENSE.

from zope.interface import Interface


class IListingView(Interface):
    """Senaite.App.Listing View
    """


class IAjaxListingView(Interface):
    """Senaite Core Ajax Listing View
    """


class IListingViewAdapter(Interface):
    """Marker that allows to modify the behavior of ListingView
    """

    def before_render(self):
        """Before render hook
        """

    def folder_item(self, obj, item, index):
        """folder_item hook
        """


class IChildFolderItems(Interface):
    """Adapter to retrieve the child folderitems
    """

    def get_children(parent_uid, child_uids=None):
        """Return the child folderitems
        """
