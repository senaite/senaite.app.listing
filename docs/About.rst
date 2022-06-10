.. image:: https://raw.githubusercontent.com/senaite/senaite.app.listing/master/static/logo_pypi.png
   :target: https://github.com/senaite/senaite.app.listing
   :alt: senaite.app.listing
   :height: 128px


*ReactJS powered listing tables for SENAITE LIMS*
=================================================

.. image:: https://img.shields.io/pypi/v/senaite.app.listing.svg?style=flat-square
   :target: https://pypi.python.org/pypi/senaite.app.listing

.. image:: https://img.shields.io/github/issues-pr/senaite/senaite.app.listing.svg?style=flat-square
   :target: https://github.com/senaite/senaite.app.listing/pulls

.. image:: https://img.shields.io/github/issues/senaite/senaite.app.listing.svg?style=flat-square
   :target: https://github.com/senaite/senaite.app.listing/issues

.. image:: https://img.shields.io/badge/README-GitHub-blue.svg?style=flat-square
   :target: https://github.com/senaite/senaite.app.listing#readme

.. image:: https://img.shields.io/badge/Built%20with-%E2%9D%A4-red.svg
   :target: https://github.com/senaite/senaite.app.listing

.. image:: https://img.shields.io/badge/Made%20for%20SENAITE-%E2%AC%A1-lightgrey.svg
   :target: https://www.senaite.com


About
=====

This package provides a ReactJS based listing tables for SENAITE LIMS.

`ReactJS`_ is a declarative, efficient, and flexible JavaScript library for
building user interfaces built by `Facebook`_ and is licensed under the `MIT`_
License.


Installation
============

Please follow the installations instructions for `Plone 5`_ and
`senaite.lims`_.

To install SENAITE.APP.LISTING, you have to add `senaite.app.listing` into the
`eggs` list inside the `[buildout]` section of your `buildout.cfg`::

   [buildout]
   index = https://pypi.org/simple/
   extends = https://dist.plone.org/release/5.2-latest/versions.cfg
   find-links =
       https://dist.plone.org/release/5.2-latest/
       https://dist.plone.org/thirdparty/
   eggs =
       Plone
       senaite.lims
   zcml =
   eggs-directory = ${buildout:directory}/eggs

   [instance]
   recipe = plone.recipe.zope2instance
   user = admin:admin
   http-address = 127.0.0.1:8080
   eggs =
       ${buildout:eggs}
   zcml =
       ${buildout:zcml}


**Note**

The above example works for the buildout created by the unified
installer. If you however have a custom buildout you might need to add
the egg to the `eggs` list in the `[instance]` section rather than
adding it in the `[buildout]` section.

Also see this section of the Plone documentation for further details:
https://docs.plone.org/4/en/manage/installing/installing_addons.html

**Important**

For the changes to take effect you need to re-run buildout from your
console::

   bin/buildout


Installation Requirements
-------------------------

The following versions are required for SENAITE.APP.LISTING:

-  senaite.lims >= 2.1.0


.. _Plone 5: https://docs.plone.org/manage/installing/installation.html
.. _senaite.lims: https://github.com/senaite/senaite.lims#installation
.. _ReactJS: https://reactjs.org
.. _Facebook: https://github.com/facebook/react
.. _MIT: https://github.com/facebook/react/blob/master/LICENSE
