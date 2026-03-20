# --
# Copyright (C) 2026 INTELICOLAB
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (GPL). If you
# did not receive this file, see https://www.gnu.org/licenses/gpl-3.0.txt.
# --

package Kernel::GenericInterface::Operation::Extensions::Common;

use strict;
use warnings;

our @ObjectDependencies = (
    'Kernel::System::Group',
    'Kernel::System::Log',
);

sub new {
    my ( $Type, %Param ) = @_;
    my $Self = {};
    bless( $Self, $Type );
    return $Self;
}

=head2 CheckGroupPermission()

Verify if a user has the specified permission level in a given group.

    my $HasPermission = $CommonObject->CheckGroupPermission(
        UserID     => 123,
        GroupName  => 'users',
        Permission => 'ro',    # 'ro' or 'rw'
    );

Returns 1 if the user has permission, 0 otherwise.

=cut

sub CheckGroupPermission {
    my ( $Self, %Param ) = @_;

    # Check required params.
    for my $Needed (qw(UserID GroupName Permission)) {
        if ( !$Param{$Needed} ) {
            $Kernel::OM->Get('Kernel::System::Log')->Log(
                Priority => 'error',
                Message  => "CheckGroupPermission: Need $Needed!",
            );
            return 0;
        }
    }

    my $HasPermission = $Kernel::OM->Get('Kernel::System::Group')->PermissionCheck(
        UserID    => $Param{UserID},
        GroupName => $Param{GroupName},
        Type      => $Param{Permission},
    );

    return $HasPermission ? 1 : 0;
}

=head2 ValidateRequiredParams()

Validate that all required parameters are present in the data hash.

    my $Result = $CommonObject->ValidateRequiredParams(
        Data     => \%Data,
        Required => [ 'Object', 'Key' ],
    );

Returns:
    { Success => 1 }
or:
    { Success => 0, MissingParameter => 'ParamName' }

=cut

sub ValidateRequiredParams {
    my ( $Self, %Param ) = @_;

    my $Data     = $Param{Data}     || {};
    my $Required = $Param{Required} || [];

    for my $ParamName ( @{$Required} ) {
        if ( !defined $Data->{$ParamName} || $Data->{$ParamName} eq '' ) {
            return {
                Success          => 0,
                MissingParameter => $ParamName,
            };
        }
    }

    return { Success => 1 };
}

1;
