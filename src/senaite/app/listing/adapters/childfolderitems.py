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
