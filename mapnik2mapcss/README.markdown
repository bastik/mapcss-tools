Helper script to convert Mapnik xml to MapCSS
=============================================

This scripts aids the conversion of Mapnik xml to a similar or equivalent MapCSS Style.

Caveats
-------
Some things are hard to do with a simple script and may need manual work:

*   Proper translation of Mapnik Layers without cluttering MapCSS Style

*   Merging the `*-casing` Layers and using MapCSS `casing-*` properties instead

*   Translation of Database Queries inside Mapnik Layer elements

*   ...
 
Getting started
---------------

*   Check out the OpenStreetMap Mapnik style:

    `svn co http://svn.openstreetmap.org/applications/rendering/mapnik mapnik-osm`

*   Use the script `generate_xml.py` from that repository to create a proper Mapnik xml from the templates (call it e.g. `my_osm.xml`). You will need a proper database setup as described in the osm wiki.

*   Run the script:

    `./Mapnik2MapCSS.pl --scale2zoom examples/scale2zoom.pl -- data/my_osm.xml`
    
    If you are getting errors, start with small extracts from the file `my_osm.xml`. Using the option `--output-styles`, only Style elements will be considered, otherwise the Layer elements take precedence and matching Layer - Style pairs are required in the xml.

