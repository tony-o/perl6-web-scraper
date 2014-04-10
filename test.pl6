#!/usr/bin/env perl6

use lib './lib';

use Web::Scraper;

my $data = q{

<data>
  <t>test1</t>
  <t>test2</t>
  <e>etest</e>
  <t>test3</t>
  <t>test4</t>
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
    name => 'TEXT'
  };
  process 'e', 'e[]' => sub ($elem) {
    return $count++;
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
