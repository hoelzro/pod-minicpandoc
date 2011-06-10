package Pod::Cpandoc;
use strict;
use warnings;
use base 'Pod::Perldoc';
use HTTP::Tiny;
use File::Temp 'tempfile';

our $VERSION = '0.01';

sub scrape_documentation_for {
    my $self   = shift;
    my $module = shift;

    my $ua = HTTP::Tiny->new;
    my $response = $ua->get(
        "http://api.metacpan.org/pod/$module",
        { headers => { 'Content-Type' => 'application/x-perl' } },
    );
    return unless $response->{success};

    $module =~ s/::/-/g;
    my ($fh, $fn) = tempfile("${module}-XXXX", UNLINK => 1);
    print { $fh } $response->{content};
    close $fh;

    return $fn;
}

sub grand_search_init {
    my $self = shift;
    my @found = $self->SUPER::grand_search_init(@_);

    if (@found == 0) {
        my $pages = shift;

        for my $module (@$pages) {
            push @found, $self->scrape_documentation_for($module);
        }
    }

    return @found;
}

sub opt_V {
    my $self = shift;

    print "Cpandoc v$VERSION, ";

    return $self->SUPER::opt_V(@_);
}

1;

__END__

=head1 NAME

Pod::Cpandoc - a perldoc that works for modules you don't have

=head1 SYNOPSIS

    cpandoc Acme::BadExample
        -- works even if you don't have Acme::BadExample installed!

    cpandoc -v '$?'
        -- passes everything through to regular perldoc

    cpandoc -m Acme::BadExample | grep system
        -- options are respected even if the module was scraped

    vim `cpandoc -l Web::Scraper`
        -- getting the idea yet?

=head1 SNEAKY INSTALL

    cpanm Pod::Cpandoc
    alias perldoc=cpandoc

This should work fine since cpandoc respects all perldoc commands.
It's a subclass that just falls back to scraping L<http://search.cpan.org>.

=head1 SEE ALSO

The sneaky install was inspired by L<https://github.com/defunkt/hub>

=head1 AUTHOR

Shawn M Moore C<sartak@gmail.com>

=head1 COPYRIGHT

Copyright 2011 Shawn M Moore.

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut

