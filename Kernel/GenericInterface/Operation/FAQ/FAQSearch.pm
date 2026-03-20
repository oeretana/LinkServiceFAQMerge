# --
# Copyright (C) 2026 INTELICOLAB
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (GPL). If you
# did not receive this file, see https://www.gnu.org/licenses/gpl-3.0.txt.
# --

package Kernel::GenericInterface::Operation::FAQ::FAQSearch;

use strict;
use warnings;

use Kernel::System::VariableCheck qw(:all);

use parent qw(Kernel::GenericInterface::Operation::Common);

our $ObjectManagerDisabled = 1;

sub new {
    my ( $Type, %Param ) = @_;

    my $Self = {};
    bless( $Self, $Type );

    for my $Needed (qw(DebuggerObject WebserviceID)) {
        if ( !$Param{$Needed} ) {
            return {
                Success      => 0,
                ErrorMessage => "Got no $Needed!",
            };
        }
        $Self->{$Needed} = $Param{$Needed};
    }

    return $Self;
}

sub Run {
    my ( $Self, %Param ) = @_;

    my ( $UserID, $UserType ) = $Self->Auth(%Param);

    return $Self->ReturnError(
        ErrorCode    => 'FAQSearch.AuthFail',
        ErrorMessage => 'FAQSearch: Could not authenticate.',
    ) if !$UserID;

    # FAQ is a soft dependency — check if the module is available.
    my $FAQObject;
    eval {
        $FAQObject = $Kernel::OM->Get('Kernel::System::FAQ');
    };
    if ($@) {
        return $Self->ReturnError(
            ErrorCode    => 'FAQSearch.ModuleNotAvailable',
            ErrorMessage => 'FAQSearch: FAQ module is not installed.',
        );
    }

    # Get all FAQ state IDs (internal, external, public) — agent-level access.
    my %States = $FAQObject->StateList(
        UserID => $UserID,
    );
    my @AllStateIDs = sort { $a <=> $b } keys %States;

    # Build search params.
    my %SearchParams = (
        StateIDs => \@AllStateIDs,
        UserID   => $UserID,
    );

    # Optional params — only include if provided.
    if ( defined $Param{Data}{Title} && $Param{Data}{Title} ne '' ) {
        $SearchParams{Title} = $Param{Data}{Title};
    }

    if ( defined $Param{Data}{What} && $Param{Data}{What} ne '' ) {
        $SearchParams{What} = $Param{Data}{What};
    }

    if ( defined $Param{Data}{Keyword} && $Param{Data}{Keyword} ne '' ) {
        $SearchParams{Keyword} = $Param{Data}{Keyword};
    }

    if ( defined $Param{Data}{LanguageIDs} ) {
        my $LanguageIDs = $Param{Data}{LanguageIDs};
        $LanguageIDs = [$LanguageIDs] if !IsArrayRefWithData($LanguageIDs);
        $SearchParams{LanguageIDs} = $LanguageIDs if IsArrayRefWithData($LanguageIDs);
    }

    if ( defined $Param{Data}{CategoryIDs} ) {
        my $CategoryIDs = $Param{Data}{CategoryIDs};
        $CategoryIDs = [$CategoryIDs] if !IsArrayRefWithData($CategoryIDs);
        $SearchParams{CategoryIDs} = $CategoryIDs if IsArrayRefWithData($CategoryIDs);
    }

    if ( defined $Param{Data}{Limit} && $Param{Data}{Limit} ne '' ) {
        $SearchParams{Limit} = $Param{Data}{Limit};
    }

    if ( defined $Param{Data}{OrderBy} ) {
        my $OrderBy = $Param{Data}{OrderBy};
        $OrderBy = [$OrderBy] if !IsArrayRefWithData($OrderBy);
        $SearchParams{OrderBy} = $OrderBy if IsArrayRefWithData($OrderBy);
    }

    if ( defined $Param{Data}{OrderByDirection} ) {
        my $OrderByDirection = $Param{Data}{OrderByDirection};
        $OrderByDirection = [$OrderByDirection] if !IsArrayRefWithData($OrderByDirection);
        $SearchParams{OrderByDirection} = $OrderByDirection if IsArrayRefWithData($OrderByDirection);
    }

    if ( defined $Param{Data}{ValidIDs} ) {
        my $ValidIDs = $Param{Data}{ValidIDs};
        $ValidIDs = [$ValidIDs] if !IsArrayRefWithData($ValidIDs);
        $SearchParams{ValidIDs} = $ValidIDs if IsArrayRefWithData($ValidIDs);
    }

    my @ItemIDs = $FAQObject->FAQSearch(
        %SearchParams,
    );

    return {
        Success => 1,
        Data    => {
            ID => \@ItemIDs,
        },
    };
}

1;
