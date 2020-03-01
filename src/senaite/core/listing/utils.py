# -*- coding: utf-8 -*-
#
# This file is part of SENAITE.CORE.LISTING.
#
# SENAITE.CORE.LISTING is free software: you can redistribute it and/or modify
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
# Copyright 2018-2020 by it's authors.
# Some rights reserved, see README and LICENSE.

from senaite.core.listing.interfaces import IListingView
import collections


def add_review_state(listing, review_state, before=None, after=None):
    """Adds a new review state in the listing
    """
    if not IListingView.providedBy(listing):
        raise ValueError("Type not supported: {}".format(repr(type(listing))))

    if not review_state:
        return False

    # Do nothing if the review state is already there
    ids = map(lambda st: st["id"], listing.review_states)
    if review_state["id"] in ids:
        return False

    if before and before not in ids:
        raise ValueError("Review state '{}' does not exist".format(before))

    if after and after not in ids:
        raise ValueError("Review state '{}' does not exist".format(after))

    idx = len(ids)
    if before:
        idx = ids.index(before)
    elif after:
        idx = ids.index(after) + 1
    listing.review_states.insert(idx, review_state)
    return True


def add_column(listing, column_id, column_values, before=None, after=None,
               review_states=None):
    """Adds a column to the listing
    """
    if not IListingView.providedBy(listing):
        raise ValueError("Type not supported: {}".format(repr(type(listing))))

    if not column_id or not column_values:
        return False

    ids = listing.columns.keys()
    if column_id in ids:
        listing.columns[column_id].update(column_values)
        return True

    if before and before not in ids:
        raise ValueError("Column '{}' does not exist".format(before))

    if after and after not in ids:
        raise ValueError("Column '{}' does not exist".format(after))

    new_dict = collections.OrderedDict()
    for key, item in listing.columns.copy().items():
        if before == key:
            new_dict[column_id] = column_values
        new_dict[key] = item
        if after == key:
            new_dict[column_id] = column_values
    listing.columns = new_dict

    if not review_states:
        return True

    new_states = []
    for state in listing.review_states:
        rv_state = state.copy()
        if rv_state["id"] in review_states:
            cols = rv_state.get("columns", [])
            if column_id not in cols:
                idx = len(cols)
                if before and before in cols:
                    idx = cols.index(before)
                elif after and after in cols:
                    idx = cols.index(after) + 1
                cols.insert(idx, column_id)
                state["columns"] = cols
        new_states.append(rv_state)
    listing.review_states = new_states
    return True
