#!/usr/bin/env perl6
use XML;
use XML::Query;

my $local = 0;
class Web::Scraper {
  has Callable $.main;
  has $.ctx is rw;
  has %.d   is rw;

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
      %.d{$atag} = Array.new if $flag eq 'A';
      %.d{$atag} = '' if $flag ne 'A';
      if $v ~~ Hash {
        for @elems -> $e {
          my %push;
          my $spush;
          for $v.kv -> $k, $v {
            for @($e.contents) -> $e {
              %push{$k} = $e.text if $flag eq 'A';
              $spush    = "$k={$e.text}\n" if $flag ne 'A';
            }
          }
          %.d{$atag}.push(\%push) if $flag eq 'A';
          %.d{$atag} ~= "$spush" if $flag ne 'A';
        }
      } elsif $v ~~ Callable {
        my $spush;
        for @elems -> $e {
          $spush ~= "{$v.(\$e)}" if $flag ne 'A';
          %.d{$atag}.push($v.(\$e)) if $flag eq 'A';
        }
        $.d{$atag} = $spush if $flag ne 'A';
      } elsif $v ~~ Str {
        $.d{$atag} = '';
        for @elems -> $e {
          for @($e.contents) -> $e {
            $.d{$atag} ~= $e.text;
          }
        }
      }
    }
  }

  multi method scrape (Str $data) {
    $.ctx = XML::Query.new: xml => from-xml($data);
    @.d = ();
    $.main.();
  }

  sub scraper (&block) is export {
    my $self = Web::Scraper.new(main => &block);
    my $p    = $local;
    $local++;
    sub process ($d1, %d2) is export {
      my $p;
      $p.say;
      %d2.values[0].say;
      if %d2.values[0].can('scrape') {
        $self.ctx.($d1).data.say;
      } else {
        my @elems = $self.ctx.($d1).elems;
        $self.handler($d1, %d2, @elems);
      }
    }
    return $self;
  }
};

