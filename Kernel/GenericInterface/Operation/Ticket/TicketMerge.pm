# --
# Copyright (C) 2026 INTELICOLAB
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (GPL). If you
# did not receive this file, see https://www.gnu.org/licenses/gpl-3.0.txt.
# --

package Kernel::GenericInterface::Operation::Ticket::TicketMerge;

use strict;
use warnings;

use Kernel::System::VariableCheck qw(:all);

use parent qw(
    Kernel::GenericInterface::Operation::Common
    Kernel::GenericInterface::Operation::Ticket::Common
);

our $ObjectManagerDisabled = 1;

sub new {
    my ( $Type, %Param ) = @_;

    my $Self = {};
    bless( $Self, $Type );

    # Init from Ticket::Common (which inherits from Operation::Common).
    my $Result = $Self->Init(
        WebserviceID => $Param{WebserviceID},
    );

    if ( !$Result->{Success} ) {
        $Self->ReturnError(
            ErrorCode    => 'TicketMerge.InternalError',
            ErrorMessage => 'TicketMerge: Could not initialize.',
        );
        return;
    }

    return $Self;
}

sub Run {
    my ( $Self, %Param ) = @_;

    my ( $UserID, $UserType ) = $Self->Auth(%Param);

    return $Self->ReturnError(
        ErrorCode    => 'TicketMerge.AuthFail',
        ErrorMessage => 'TicketMerge: Could not authenticate.',
    ) if !$UserID;

    my $TicketObject = $Kernel::OM->Get('Kernel::System::Ticket');

    # Resolve MainTicketID — accept ID or Number.
    my $MainTicketID = $Param{Data}{MainTicketID};
    if ( !$MainTicketID && $Param{Data}{MainTicketNumber} ) {
        $MainTicketID = $TicketObject->TicketIDLookup(
            TicketNumber => $Param{Data}{MainTicketNumber},
            UserID       => $UserID,
        );
    }

    return $Self->ReturnError(
        ErrorCode    => 'TicketMerge.MissingParameter',
        ErrorMessage => 'TicketMerge: MainTicketID or MainTicketNumber is required.',
    ) if !$MainTicketID;

    # Resolve MergeTicketID — accept ID or Number.
    my $MergeTicketID = $Param{Data}{MergeTicketID};
    if ( !$MergeTicketID && $Param{Data}{MergeTicketNumber} ) {
        $MergeTicketID = $TicketObject->TicketIDLookup(
            TicketNumber => $Param{Data}{MergeTicketNumber},
            UserID       => $UserID,
        );
    }

    return $Self->ReturnError(
        ErrorCode    => 'TicketMerge.MissingParameter',
        ErrorMessage => 'TicketMerge: MergeTicketID or MergeTicketNumber is required.',
    ) if !$MergeTicketID;

    # Cannot merge a ticket into itself.
    if ( $MainTicketID == $MergeTicketID ) {
        return $Self->ReturnError(
            ErrorCode    => 'TicketMerge.InvalidParameter',
            ErrorMessage => 'TicketMerge: MainTicketID and MergeTicketID cannot be the same.',
        );
    }

    # Validate that both tickets exist.
    my %MainTicket = $TicketObject->TicketGet(
        TicketID => $MainTicketID,
        UserID   => $UserID,
    );

    return $Self->ReturnError(
        ErrorCode    => 'TicketMerge.NotFound',
        ErrorMessage => "TicketMerge: Main ticket with ID $MainTicketID not found.",
    ) if !%MainTicket;

    my %MergeTicket = $TicketObject->TicketGet(
        TicketID => $MergeTicketID,
        UserID   => $UserID,
    );

    return $Self->ReturnError(
        ErrorCode    => 'TicketMerge.NotFound',
        ErrorMessage => "TicketMerge: Merge ticket with ID $MergeTicketID not found.",
    ) if !%MergeTicket;

    # Check rw permission on BOTH tickets.
    my $MainPermission = $TicketObject->TicketPermission(
        Type     => 'rw',
        TicketID => $MainTicketID,
        UserID   => $UserID,
    );

    return $Self->ReturnError(
        ErrorCode    => 'TicketMerge.AccessDenied',
        ErrorMessage => "TicketMerge: No write permission on main ticket $MainTicketID.",
    ) if !$MainPermission;

    my $MergePermission = $TicketObject->TicketPermission(
        Type     => 'rw',
        TicketID => $MergeTicketID,
        UserID   => $UserID,
    );

    return $Self->ReturnError(
        ErrorCode    => 'TicketMerge.AccessDenied',
        ErrorMessage => "TicketMerge: No write permission on merge ticket $MergeTicketID.",
    ) if !$MergePermission;

    # Execute the merge — this is irreversible.
    my $Success = $TicketObject->TicketMerge(
        MainTicketID  => $MainTicketID,
        MergeTicketID => $MergeTicketID,
        UserID        => $UserID,
    );

    return $Self->ReturnError(
        ErrorCode    => 'TicketMerge.OperationFailed',
        ErrorMessage => 'TicketMerge: Merge operation failed.',
    ) if !$Success;

    return {
        Success => 1,
        Data    => {
            Success => 1,
        },
    };
}

1;
