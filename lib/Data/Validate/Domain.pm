package Data::Validate::Domain;

use strict;
use warnings;

use Net::Domain::TLD qw(tld_exists);

use Exporter qw( import );

## no critic (Modules::ProhibitAutomaticExportation)
our @EXPORT = qw(
    is_domain
    is_hostname
    is_domain_label
);

our $VERSION = '0.10';

=head1 NAME

Data::Validate::Domain - domain validation methods

=head1 SYNOPSIS

  use Data::Validate::Domain qw(is_domain);

  # as a function
  my $test = is_domain($suspect);
  die "$test is not a domain" unless defined $test;

  # or

  my $test = is_domain($suspect, \%options);
  die "$test is not a domain" unless defined $test;

  # or as an object
  my $v = Data::Validate::Domain->new(%options);

  my $test = $v->is_domain($suspect);
  die "$test is not a domain" unless defined $test;

=head1 DESCRIPTION

This module collects domain validation routines to make input validation,
and untainting easier and more readable.

All functions return an untainted value if the test passes, and undef if
it fails.  This means that you should always check for a defined status explicitly.
Don't assume the return will be true. (e.g. is_username('0'))

The value to test is always the first (and often only) argument.

=head1 FUNCTIONS

=over 4

=item B<new> - constructor for OO usage

  $obj = Data::Validate::Domain->new();
  my %options = (
		domain_allow_underscore => 1,
  );

  or

  my %options = (
		domain_allow_single_label => 1,
		domain_private_tld => {
			'privatetld1 '   =>      1,
			'privatetld2'    =>      1,
		}
  );

  or

  my %options = (
		domain_allow_single_label => 1,
		domain_private_tld 	  => qr /^(?:privatetld1|privatetld2)$/,
  );




  $obj = Data::Validate::Domain->new(%options);


=over 4

=item I<Description>

Returns a Data::Validator::Domain object.  This lets you access all the validator function
calls as methods without importing them into your namespace or using the clumsy
Data::Validate::Domain::function_name() format.

=item I<Options>

=over 4

=item	B<domain_allow_underscore>

According to RFC underscores are forbidden in "hostnames" but not "domainnames".
By default is_domain,is_domain_label,  and is_hostname will fail if you include underscores, setting
this to a true value with authorize the use of underscores in all functions.

=item	B<domain_allow_single_label>

By default is_domain will fail if you ask it to verify a domain that only has a single label
i.e. 'neely.cx' is good, but 'com' would fail.  If you set this option to a true value then
is_domain will allow single label domains through.  This is most likely to be useful in
combination with B<domain_private_tld>

=item B<domain_private_tld>

By default is_domain requires all domains to have a valid TLD (i.e. com, net, org, uk, etc),
this is verified using the Net::Domain::TLD module.  This behavior can be extended in two
different ways.  Either a hash reference can be supplied keyed by the additional TLD's, or you
can supply a precompiled regular expression.

NOTE:  The TLD is normalized to the lower case form prior to the check being done.  This is
done only for the TLD check, and does not alter the output in any way.

	The hash reference example:	

		domain_private_tld => {
			'privatetld1 '   =>      1,
			'privatetld2'    =>      1,
		}

	The precompiled regualar expression example:

		domain_private_tld 	  => qr /^(?:privatetld1|privatetld2)$/,



=back

=item I<Returns>

Returns a Data::Validate::Domain object

=back

=cut

sub new {
    my $class = shift;

    return bless {@_}, ref($class) || $class;
}

# -------------------------------------------------------------------------------

=pod

=item B<is_domain> - does the value look like a domain name?

  is_domain($value);
  or
  $obj->is_domain($value);
  or
  is_domain($value,\%options);
  or
  $obj->is_domain($value,\%options);


=over 4

=item I<Description>

Returns the untainted domain name if the test value appears to be a well-formed
domain name.

Note:  See B<new> for list of options and how those alter the behavior of this
function.

=item I<Arguments>

=over 4

=item $value

The potential domain to test.

=back

=item I<Returns>

Returns the untainted domain on success, undef on failure.

=item I<Notes, Exceptions, & Bugs>

The function does not make any attempt to check whether a domain
actually exists. It only looks to see that the format is appropriate.

A dotted quad (such as 127.0.0.1) is not considered a domain and will return false.
See L<Data::Validate::IP(3)> for IP Validation.

Performs a lookup via Net::Domain::TLD to verify that the TLD is valid for this domain.

Does not consider "domain.com." a valid format.

=item I<From RFC 952>

   A "name" (Net, Host, Gateway, or Domain name) is a text string up
   to 24 characters drawn from the alphabet (A-Z), digits (0-9), minus
   sign (-), and period (.).  Note that periods are only allowed when
   they serve to delimit components of "domain style names".

   No blank or space characters are permitted as part of a
   name. No distinction is made between upper and lower case.  The first
   character must be an alpha character [Relaxed in RFC 1123] .  The last
   character must not be a minus sign or period.

=item I<From RFC 1035>

    labels          63 octets or less
    names           255 octets or less

    [snip] limit the label to 63 octets or less.

    To simplify implementations, the total length of a domain name (i.e.,
    label octets and label length octets) is restricted to 255 octets or
    less.

=item I<From RFC 1123>

    One aspect of host name syntax is hereby changed: the
    restriction on the first character is relaxed to allow either a
    letter or a digit.  Host software MUST support this more liberal
    syntax.

    Host software MUST handle host names of up to 63 characters and
    SHOULD handle host names of up to 255 characters.


=back

=cut

sub is_domain {
    my ( $value, $opt ) = _maybe_oo(@_);

    return unless defined($value);

    my $length = length($value);
    return unless ( $length > 0 && $length <= 255 );

    my @bits;
    foreach my $label ( split /\./, $value, -1 ) {
        my $bit = is_domain_label( $label, $opt );
        return unless defined $bit;
        push( @bits, $bit );
    }
    my $tld = $bits[-1];

    #domain_allow_single_label set to true disables this check
    unless ( defined $opt && $opt->{domain_allow_single_label} ) {

        #All domains have more then 1 label (neely.cx good, com not good)
        return unless ( @bits >= 2 );
    }

    #If the option to enable domain_private_tld is enabled
    #and a private domain is specified, then we return if that matches

    if (   defined $opt
        && exists $opt->{domain_private_tld}
        && ref( $opt->{domain_private_tld} ) ) {
        my $lc_tld = lc($tld);
        if ( ref( $opt->{domain_private_tld} ) eq 'HASH' ) {
            if ( exists $opt->{domain_private_tld}->{$lc_tld} ) {
                return join( '.', @bits );
            }
        }
        else {
            if ( $tld =~ $opt->{domain_private_tld} ) {
                return join( '.', @bits );
            }
        }
    }

    #Verify domain has a valid TLD
    return unless tld_exists($tld);

    return join( '.', @bits );
}

# -------------------------------------------------------------------------------

=pod

=item B<is_hostname> - does the value look like a hostname

  is_hostname($value);
  or
  $obj->is_hostname($value);
  or
  is_hostname($value,\%options);
  or
  $obj->is_hostname($value,\%options);


=over 4

=item I<Description>

Returns the untainted hostname if the test value appears to be a well-formed
hostname.

Note:  See B<new> for list of options and how those alter the behavior of this
function.

=item I<Arguments>

=over 4

=item $value

The potential hostname to test.

=back

=item I<Returns>

Returns the untainted hostname on success, undef on failure.

=item I<Notes, Exceptions, & Bugs>

The function does not make any attempt to check whether a hostname
actually exists. It only looks to see that the format is appropriate.

Functions much like is_domain, except that it does not verify whether or
not a valid TLD has been supplied and allows for there to only
be a single component of the hostname (i.e www)

Hostnames might or might not have a valid TLD attached.

=back

=cut

sub is_hostname {
    my ( $value, $opt ) = _maybe_oo(@_);

    return unless defined($value);

    my $length = length($value);
    return unless ( $length > 0 && $length <= 255 );

    #	return is_domain_label($value) unless $value =~ /\./;  #If just a simple hostname

    #Anything past here has multiple bits in it
    my @bits;
    foreach my $label ( split /\./, $value, -1 ) {
        my $bit = is_domain_label( $label, $opt );
        return unless defined $bit;
        push( @bits, $bit );
    }

    #We do not verify TLD for hostnames, as hostname.subhost is a valid hostname

    return join( '.', @bits );

}

=pod

=item B<is_domain_label> - does the value look like a domain label?

  is_domain_label($value);
  or
  $obj->is_domain_label($value);
  or
  is_domain_label($value,\%options);
  or
  $obj->is_domain_label($value,\%options);


=over 4

=item I<Description>

Returns the untainted domain label if the test value appears to be a well-formed
domain label.

Note:  See B<new> for list of options and how those alter the behavior of this
function.

=item I<Arguments>

=over 4

=item $value

The potential ip to test.

=back

=item I<Returns>

Returns the untainted domain label on success, undef on failure.

=item I<Notes, Exceptions, & Bugs>

The function does not make any attempt to check whether a domain label
actually exists. It only looks to see that the format is appropriate.

=cut

sub is_domain_label {
    my ( $value, $opt ) = _maybe_oo(@_);

    return unless defined($value);

    #Fix Bug: 41033
    return if ( $value =~ /\n/ );

    # bail if we are dealing with more then just a hostname
    return if ( $value =~ /\./ );
    my $length = length($value);
    my $hostname;
    if ( $length == 1 ) {
        if ( defined $opt && $opt->{domain_allow_underscore} ) {
            ($hostname) = $value =~ /^([\dA-Za-z\_])$/;
        }
        else {
            ($hostname) = $value =~ /^([\dA-Za-z])$/;
        }
    }
    elsif ( $length > 1 && $length <= 63 ) {
        if ( defined $opt && $opt->{domain_allow_underscore} ) {
            ($hostname)
                = $value =~ /^([\dA-Za-z\_][\dA-Za-z\-\_]*[\dA-Za-z])$/;
        }
        else {
            ($hostname) = $value =~ /^([\dA-Za-z][\dA-Za-z\-]*[\dA-Za-z])$/;
        }
    }
    else {
        return;
    }
    return $hostname;
}

sub _maybe_oo {
    if ( ref $_[0] ) {
        return @_[ 1, 0 ];
    }
    else {
        return @_[ 0, 1 ];
    }
}

1;
__END__
#



# -------------------------------------------------------------------------------

=pod


=back

=back

=head1 SEE ALSO

B<[RFC 1034] [RFC 1035] [RFC 2181] [RFC 1123]>

=over 4

=item  L<Data::Validate(3)>

=item  L<Data::Validate::IP(3)>

=back


=head1 AUTHOR

Neil Neely <F<neil@neely.cx>>.

=head1 ACKNOWLEDGEMENTS

Thanks to Richard Sonnen <F<sonnen@richardsonnen.com>> for writing the Data::Validate module.

Thanks to Len Reed <F<lreed@levanta.com>> for helping develop the options mechanism for Data::Validate modules.

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2005-2007 Neil Neely.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.2 or,
at your option, any later version of Perl 5 you may have available.


=cut
