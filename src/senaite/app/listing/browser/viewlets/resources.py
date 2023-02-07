# -*- coding: utf-8 -*-

from plone.app.layout.viewlets import ViewletBase
from Products.Five.browser.pagetemplatefile import ViewPageTemplateFile


class ResourcesViewlet(ViewletBase):

    def index(self):
        return ViewPageTemplateFile("../static/resources.pt")
