Helper script to convert Mapnik xml to MapCSS
=============================================

This scripts aids the conversion of Mapnik xml to a similar or equivalent MapCSS Style.

Getting started
---------------

*   Check out the OpenStreetMap Mapnik style:

    `svn co http://svn.openstreetmap.org/applications/rendering/mapnik mapnik-osm`

*   Use the script `generate_xml.py` from that repository to create a proper Mapnik xml from the templates (call it e.g. `my_osm.xml`). You will need a proper database setup as described in the osm wiki.

*   Run the script. See

    `./Mapnik2MapCSS.pl --help`
    
    for available options. If you are getting errors, use the `--layers` option to convert layers one by one. 

Caveats
-------
Some things are hard to do with a simple script and may need manual work:

*   Proper translation of Mapnik Layers without cluttering MapCSS Style

*   Merging the `*-casing` Layers and using MapCSS `casing-*` properties instead

*   Translation of Database Queries inside Mapnik Layer elements

*   ...

Dependencies
------------

`XML::Parser` and `Parse::RecDescent`. In Ubuntu 11.04, these are provided by the packages `libxml-perl` and `libparse-recdescent-perl`.
