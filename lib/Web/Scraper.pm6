#!/usr/bin/env perl6
use XML;
use XML::Query;

my $local = 1;
class Web::Scraper {
  has Callable $.main;
  has $.ctx is rw;
  has %.d   is rw;
  has $.id  is rw;

  method handler ($tag, %val, @elems) {
    my $flag; # flags can be [] for array, 
    my $atag;
    my @o;
    my $o;
    my $grab = sub ($elem, $val is copy) {
      my $f = $val.substr(0,1) eq '@' ?? 'A' !! '';
      $val = $val.substr(1) if $f eq 'A';
      return $f eq 'A' ?? $elem.attribs{$val} !! $elem.contents[0].text;
      return '0';
    };
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
            %push{$k} = $grab($e, $v) if $flag eq 'A';
            $spush    = "$k={$grab($e, $v)}\n" if $flag ne 'A';
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
          $.d{$atag} ~= $grab($e, $v) if $flag ne 'A';
          $.d{$atag}.push($grab($e, $v)) if $flag eq 'A';
        }
      }
    }
  }

  multi method scrape (Str $data, $subelem?) {
    $.ctx = XML::Query.new: xml => from-xml($data) if !$subelem.defined;
    $.ctx = XML::Query.new: xml => $subelem if $subelem.defined;
    %.d = Hash.new;

    my $*dynself = self;
    my proto process ($d1, %d2) is export {
      my $self = $*Outer::dynself;
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

