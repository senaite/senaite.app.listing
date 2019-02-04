# -*- coding: utf-8 -*-
#
# This file is part of SENAITE.CORE.LISTING
#
# Copyright 2018 by it's authors.

import doctest

import unittest2 as unittest

from Testing import ZopeTestCase as ztc

from .base import SimpleTestCase


def test_suite():
    suite = unittest.TestSuite()
    suite.addTests([
        # ztc.ZopeDocFileSuite(
        #     '../docs/Listing.rst',
        #     test_class=SimpleTestCase,
        #     optionflags=doctest.ELLIPSIS | doctest.NORMALIZE_WHITESPACE,
        # ),
    ])
    return suite
