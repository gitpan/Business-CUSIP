package Business::CUSIP;

=pod

=head1 NAME

Business::CUSIP - Verify Committee on Uniform Security Identification Procedures Numbers

=head1 SYNOPSIS

  use Business::CUSIP;
  $csp = Business::CUSIP->new('035231AH2');
  print "Looks good.\n" if $csp->is_valid;

  $csp = Business::CUSIP->new('392690QT', 1);
  $chk = $csp->check_digit;
  $csp->cusip($csp->cusip.$chk);
  print $csp->is_valid ? "Looks good." : "Invalid: ", $csp->error, "\n";

=head1 DESCRIPTION

This module helps verify CUSIPs, which are financial security identifiers
issued by the Standard & Poor's Company. This module cannot tell if a CUSIP
references a real security, but it can tell you if the given CUSIP is properly
formatted.

=cut

use strict;
use Algorithm::LUHN ();
# Add additional characters to Algorithm::LUHN::valid_chars so CUSIPs can be
# validated. 
Algorithm::LUHN::valid_chars(map {$_ => ord($_)-ord('A')+10} 'A'..'Z');
Algorithm::LUHN::valid_chars('*',36, '@',37, '#',38);

use vars qw($VERSION $ERROR);

$VERSION = '0.01';

=head1 METHODS

=over 4

=item new([CUSIP_NUMBER[, IS_FIXED_INCOME]])

The new constructor takes to optional arguments: the CUSIP number and a Boolean
value signifying whether this CUSIP refers to a fixed income security. CUSIPs
for fixed income securities are validated a little differently than other
CUSIPs.

=cut
sub new {
  my ($class, $cusip, $fixed_income) = @_;
  bless [uc($cusip), ($fixed_income || 0)], $class;
}

=item cusip([CUSIP_NUMBER])

If no argument is given to this method, it will return the current CUSIP
number. If an argument is provided, it will set the CUSIP number and then
return the CUSIP number.

=cut
sub cusip {
  my $self = shift;
  $self->[0] = uc(shift) if @_;
  return $self->[0];
}

=item is_fixed_income([TRUE_OR_FALSE])

If no argument is given to this method, it will return whether the CUSIP object
is marked as a fixed income security. If an argument is provided, it will set
the fixed income property and then return the fixed income setting.

=cut
sub is_fixed_income {
  my $self = shift;
  $self->[1] = shift if @_;
  return $self->[1];
}

=item is_valid()

Returns whether the CUSIP is valid. If it is not valid, $Business::CUSIP::ERROR
will contain a reason why.

=cut
sub is_valid {
  my $self = shift;
  # From the CUSIP spec:
  #   To avoid confusion, the fixed income issue number assignments have
  #   omitted the alphabetic "I" and numeric "1 " as well as the alphabetic
  #   ''O'' and numeric zero.
  # The issuer number is in positions 7 & 8.
  if ($self->is_fixed_income && substr($self->cusip,6,2) =~ /[I1O0]/) {
   $ERROR="Fixed income CUSIP cannot contain I, 1, O, or 0 in the issue number.";
    return 0;
  }
  return Algorithm::LUHN::is_valid($self->cusip);
}

=item check_digit()

This method returns the checksum of the given object. If the CUSIP number of
the object contains a check_digit, it is ignored. In other words this method
recalculates the check_digit each time.

=cut
sub check_digit {
  my $self = shift;
  return Algorithm::LUHN::check_digit(substr($self->cusip(), 0, 8));
}

=item Business::CUSIP::error()

Returns the current value of $Business::CUSIP::error, which holds the reason
of the most is_valid failure

=cut

sub error {
  return $Business::CUSIP::ERROR;
}

1;
__END__

=head1 CAVEATS

This module uses the Algorithm::LUHN module and it adds characters to the
C<valid_chars> map of Algorithm::LUHN. So if you rely on the default valid
map in the same program you use Business::CUSIP you might be surprised.

=head1 AUTHOR

This module was written by
Tim Ayers (http://search.cpan.org/search?author=TAYERS).

=head1 COPYRIGHT

Copyright (c) 2001 Tim Ayers. All rights reserved.

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
