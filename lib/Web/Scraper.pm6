#!/usr/bin/env perl6
use XML;
use XML::Query;
use LWP::Simple;

my $local = 1;
class Web::Scraper {
  has Callable $.main;
  has $.ctx is rw;
  has %.d   is rw;
  has $.id  is rw;

  method grab (XML::Element $elem, $val is copy) {
    my $f = $val.substr(0,1) eq '@' ?? 'A' !! '';
    $val = $val.substr(1) if $f eq 'A';
    return $f eq 'A' ?? $elem.attribs{$val} !! $elem.contents[0].text;
    return '0';
  };

  method handler ($tag, %val, @elems) {
    my $flag; # flags can be [] for array, 
    my $atag;
    my @o;
    my $o;
    for %val.kv -> $k, $v {
      $flag = '';
      $atag = $k;
      $flag = 'A' if $atag ~~ m{ '[]' $ } ;
      $atag.=subst(rx{ '[]' $ }, {''}) if $flag eq 'A';
      #do some setup
      %.d{$atag} = $(Array.new) if $flag eq 'A';
      %.d{$atag} = '' if $flag ne 'A';
      if $v ~~ Hash {
        for @elems -> $e {
          my %push;
          my $spush;
          for $v.kv -> $k, $v {
            %push{$k} = $.grab($e, $v) if $flag eq 'A';
            $spush    = "$k={$.grab($e, $v)}\n" if $flag ne 'A';
          }
          %.d{$atag}.push($(%push)) if $flag eq 'A';
          %.d{$atag} ~= "$spush" if $flag ne 'A';
        }
      } elsif $v ~~ Callable {
        my $spush;
        for @elems -> $e {
          $spush ~= "{$v.($e.clone)}" if $flag ne 'A';
          %.d{$atag}.push($v.($e.clone)) if $flag eq 'A';
        }
        $.d{$atag} = $spush if $flag ne 'A';
      } elsif $v ~~ Str {
        $.d{$atag} = '' if $flag ne 'A';
        $.d{$atag} = Array.new if $flag eq 'A';
        for @elems -> $e {
          $.d{$atag} ~= $.grab($e, $v) if $flag ne 'A';
          $.d{$atag}.push($.grab($e, $v)) if $flag eq 'A';
        }
      }
    }
  }

  method scrape (Str $data is copy, $subelem?) {

    my $success = 0;
    my $dc;
    # test to see if we got a url
    if $data.substr(0, 4) eq 'http' {
      #get html from lwp::simple
      try {
        $dc = from-xml(LWP::Simple.get($data));
        $success = 1;
      };
    }
    # test to see if we can parse as xml
    try {
      $dc = from-xml($data);
      $success = 1;
    };
    # test to see if we can slurp
    try {
      $dc = from-xml(slurp($data));
      $success = 1;
    }

    die 'Couldn\'t determine data type or parse XML' if !$subelem.defined && $success == 0;

    $.ctx = XML::Query.new: xml => $dc      if !$subelem.defined;
    $.ctx = XML::Query.new: xml => $subelem if $subelem.defined;
    %.d = Hash.new;

    my $*dynself = self;
    my proto resource (Web::Scraper $scraperbike, %d2) is export {
      my $self = $*Outer::dynself;
      my $f    = $self.ctx.(%d2.keys[0]).elems[0];
      my $v    = $self.grab($f, %d2.values[0]);
      $scraperbike.scrape($v);
      $self.d{$scraperbike.d.keys} = @($scraperbike.d.values);
    };
    my proto process ($d1, %d2) is export {
      my $self  = $*Outer::dynself;
      if %d2.values[0].can('scrape') {
        my @elems = $self.ctx.($d1).elems.clone;
        my $atag = %d2.keys[0];
        my $flag = '';
        $flag = 'A' if $atag ~~ m{ '[]' $ } ;
        $atag.=subst(rx{ '[]' $ }, {''}) if $flag eq 'A';
        %.d{$atag} = Array.new if $flag eq 'A';
        %.d{$atag} = '' if $flag ne 'A';
        for @elems -> $elem {
          %d2.values[0].scrape('', $elem);
          %.d{$atag} ~= %d2.values[0].d.clone if $flag ne 'A';
          %.d{$atag}.push( $(%d2.values[0].d.clone) ) if $flag eq 'A';
        }
      } else {
        my @elems = $self.ctx.($d1).elems;
        $self.handler($d1, %d2, @elems);
      }
    }
    $.main.();
  }

};

my sub scraper (&block) is export {
  return Web::Scraper.new(main => &block, id => $local++);
}

