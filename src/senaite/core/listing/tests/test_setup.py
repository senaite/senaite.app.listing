# -*- coding: utf-8 -*-
#
# This file is part of SENAITE.CORE.SUPERMODEL
#
# Copyright 2018 by it's authors.

from .base import SimpleTestCase


class TestSetup(SimpleTestCase):
    """Test Setup
    """

    def test_is_senaite_core_listing_installed(self):
        qi = self.portal.portal_quickinstaller
        self.assertTrue(qi.isProductInstalled("senaite.core.listing"))


def test_suite():
    from unittest import TestSuite, makeSuite
    suite = TestSuite()
    suite.addTest(makeSuite(TestSetup))
    return suite
