#!/usr/bin/env perl6

use lib './lib';

use Web::Scraper;

my $data = q{

<data>
  <t id="1">test1</t>
  <t id="2">test2</t>
  <e>etest</e>
  <t id="3">test3</t>
  <t id="4">test4</t>
  <e>etest</e>
  <nest>
    <id>1</id>
    <val>50</val>
    <sval>1</sval>
    <sval>2</sval>
    <sval>3</sval>
    <sval>43</sval>
  </nest>
  <nest>
    <id>2</id>
    <val>30</val>
    <sval>2</sval>
    <sval>3</sval>
    <sval>5</sval>
    <sval>47</sval>
  </nest>
</data>
};

my $count = 0;
my $scraper = scraper {
  process 't', 'tarray[]' => {
    name => 'TEXT',
    id   => '@id'
  };
  process 'e', 'e[]' => sub ($elem) {
    return "{$elem.contents[0].text ~ $count++}";
  };
  process 't', 'ttext[]' => 'TEXT';
  process 'nest', 'nested[]' => scraper {
    process 'id', 'id' => 'TEXT';
    process 'val', 'val' => 'TEXT';
    process 'sval', 'svals[]' => 'TEXT';
  };
}

$scraper.scrape($data);

$scraper.d.perl.say;
