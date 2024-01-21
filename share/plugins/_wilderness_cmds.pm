#!/usr/bin/perl -w

# Client commands for the 'wilderness' plugin

{ package Games::Axmud::Cmd::Plugin::WildEmpire;

    use strict;
    use warnings;
#   use diagnostics;

    use Glib qw(TRUE FALSE);

    our @ISA = qw(Games::Axmud::Generic::Plugin::Cmd Games::Axmud::Generic::Cmd Games::Axmud);

    ##################
    # Constructors

    sub new {

        # Create a new instance of this command object (there should only be one)
        #
        # Expected arguments
        #   (none besides $class)
        #
        # Return values
        #   'undef' if GA::Generic::Cmd->new reports an error
        #   Blessed reference to the new object on success

        my ($class, $check) = @_;

        # Setup
        my $self = Games::Axmud::Generic::Cmd->new('wildempire', FALSE, TRUE);
        if (! $self) {return undef};

        $self->{defaultUserCmdList} = ['wempire', 'wildempire'];
        $self->{userCmdList} = \@{$self->{defaultUserCmdList}};
        $self->{descrip} = '(wilderness plugin) Sets EmpireMUD wilderness mode',

        # Bless the object into existence
        bless $self, $class;
        return $self;
    }

    ##################
    # Methods

    sub do {

        my (
            $self, $session, $inputString, $userCmd, $standardCmd,
            $check,
        ) = @_;

        # Local variables
        my ($worldObj, $modifyFlag, $compObj);

        # Check for improper arguments
        if (defined $check) {

            return $self->improper($session, $inputString);
        }

        # Import the current world profile (for convenience)
        $worldObj = $session->currentWorld;

        # Must be connected to EmpireMUD
        if ($worldObj->name ne 'empire') {

            return $self->error(
                $session, $inputString,
                'You must be connected to EmpireMUD 2.0 (in online or offline mode) to use this'
                . ' command',
            );
        }

        # This command replaces the room statement component 'verb_exit_1' with 'ignore_line_99', or
        #   vice-versa
        # (We use the number 99 to reduced the probablity of overwriting any components the user
        #   might have added themselves)
        # We can check for their existence to see if we are modifying or reverting changes to the
        #   profile
        if (defined $worldObj->ivFind('verboseComponentList', 'verb_exit_1')) {

            $modifyFlag = TRUE;

        } elsif (defined $worldObj->ivFind('verboseComponentList', 'ignore_line_99')) {

            $modifyFlag = FALSE;

        } else {

            # Applying our modifications on top of the user's own modifications might be
            #   disastrous, so simply refuse to do it
            return $self->error(
                $session, $inputString,
                'The world profile has been modified from its pre-configured state, so this plugin'
                . ' can\'t be used to modify it further',
            );
        }

        # Convert world profile to use wilderness mode
        if ($modifyFlag) {

            # If the 'ignore_line_99' component doesn't exist, create it
            if (! $worldObj->ivExists('componentHash', 'ignore_line_99')) {

                $compObj = Games::Axmud::Obj::Component->new(
                    $session,
                    $worldObj,
                    'ignore_line_99',
                    'ignore_line',
                );

                if ($compObj) {

                    $compObj->{size} = 0;
                    $compObj->{minSize} = 0;
                    $compObj->{maxSize} = 1;
                    $compObj->{analyseMode} = 'check_line';
                    $compObj->{boldSensitiveFlag} = FALSE;
                    $compObj->{useInitialTagsFlag} = FALSE;
                    $compObj->{combineLinesFlag} = FALSE;           # Separate lines

                    $compObj->{startPatternList} = [
                        '^\+\-{20,}\+$',
                    ];
                    $compObj->{startTagList} = [];
                    $compObj->{startAllFlag} = FALSE;
                    $compObj->{startTagMode} = 'default';

                    $worldObj->ivAdd('componentHash', $compObj->name, $compObj);
                }

            } else {

                $compObj = $worldObj->ivShow('componentHash', 'ignore_line_99');
            }

            # Update IVs
            $worldObj->ivEmpty('exitAliasHash');

            $worldObj->ivSplice(
                'verboseComponentList',
                $worldObj->ivMatch('verboseComponentList', 'verb_exit_1'),
                1,
                'ignore_line_99',
            );

            # Set the painter to draw 'wilderness' rooms, by default
            $session->worldModelObj->painterObj->ivPoke('wildMode', 'wild');

            # For user's convenience, turn on autocompletion of twin exits
            $session->worldModelObj->ivPoke('autocompleteExitsFlag', TRUE);

        # Revert world profile from wilderness mode
        } else {

            # The component should still exist but, if not, create it
            if (! $worldObj->ivExists('componentHash', 'verb_exit_1')) {

                $compObj = Games::Axmud::Obj::Component->new(
                    $session,
                    $worldObj,
                    'verb_exit_1',
                    'verb_exit',
                );

                if ($compObj) {

                    $compObj->{size} = 0;
                    $compObj->{minSize} = 0;
                    $compObj->{maxSize} = 1;
                    $compObj->{analyseMode} = 'check_line';
                    $compObj->{boldSensitiveFlag} = FALSE;
                    $compObj->{useInitialTagsFlag} = FALSE;
                    $compObj->{combineLinesFlag} = FALSE;           # Separate lines

                    $compObj->{startPatternList} = [
                        '^\+\-{20,}\+$',
                    ];
                    $compObj->{startTagList} = [];
                    $compObj->{startAllFlag} = FALSE;
                    $compObj->{startTagMode} = 'default';

                    $worldObj->ivAdd('componentHash', $compObj->name, $compObj);
                }

            } else {

                $compObj = $worldObj->ivShow('componentHash', 'verb_exit_1');
            }

            # Update IVs
            $worldObj->ivPoke(
                'exitAliasHash',
                    '^\+\-{20,}\+$',
                        'n_s_e_w_nw_ne_sw_se',
            );

            $worldObj->ivSplice(
                'verboseComponentList',
                $worldObj->ivMatch('verboseComponentList', 'ignore_line_99'),
                1,
                'verb_exit_1',
            );

            # Set the painter to draw 'normal' rooms, by default
            $session->worldModelObj->painterObj->ivPoke('wildMode', 'normal');
        }

        # Operation complete. Update any automapper windows that are open, so the right widgets are
        #   sensitised/desensitised
        foreach my $otherSession ($axmud::CLIENT->ivValues('sessionHash')) {

            if ($otherSession->currentWorld->name eq 'empire') {

                if ($otherSession->mapWin) {

                    $otherSession->mapWin->restrictWidgets();
                }

                if ($otherSession->locatorTask) {

                    $otherSession->pseudoCmd('resetlocator');
                }
            }
        }

        # Show a confirmation
        if ($modifyFlag) {

            return $self->complete(
                $session, $standardCmd,
                'Operation complete. The easiest way to draw new rooms in wilderness areas is to'
                . ' enable the painter and to make it draw new rooms in wilderness mode',
            );

        } else {

            return $self->complete(
                $session, $standardCmd,
                'Operation complete - the world profile is no longer configured to use wilderness'
                . ' mode',
            );
        }
    }

    ##################
    # Accessors - set

    ##################
    # Accessors - get
}

# Package must return a true value
1
