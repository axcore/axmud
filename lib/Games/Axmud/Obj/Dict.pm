# Copyright (C) 2011-2022 A S Lewis
#
# This program is free software: you can redistribute it and/or modify it under the terms of the GNU
# General Public License as published by the Free Software Foundation, either version 3 of the
# License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without
# even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
# General Public License for more details.
#
# You should have received a copy of the GNU General Public License along with this program. If not,
# see <http://www.gnu.org/licenses/>.
#
#
# Games::Axmud::Obj::Dict
# The code that handles an Axmud dictionary

{ package Games::Axmud::Obj::Dict;

    use strict;
    use warnings;
    use diagnostics;

    use Glib qw(TRUE FALSE);

    our @ISA = qw(Games::Axmud);

    ##################
    # Constructors

    sub new {

        # Called by GA::Cmd::AddDictionary->do, SetDictionary->do, AddWorld->do,
        #   GA::Session->setupProfiles and by various 'edit' windows
        # Creates a new instance of the dictionary object
        #
        # Expected arguments
        #   $session    - The GA::Session which called this function (not stored as an IV)
        #   $name       - A unique string name for this dictionary (max 16 chars, containing
        #                   A-Za-z0-9_ - 1st char can't be number, non-Latin alphabets acceptable.
        #                   Must not exist as a key in the global hash of reserved names,
        #                   $axmud::CLIENT->constReservedHash)
        #
        # Optional arguments
        #   $language   - Which language the dictionary will use. If specified, can be any string
        #                   useful to the user, e.g. 'French', 'Francais', 'Franzoesisch'. If
        #                   'undef', the dictionary sets 'English' as its language)
        #   $tempFlag   - If set to TRUE, this is a temporary dictionary created for use with an
        #                   'edit' window; $name and $language are not checked for validity.
        #                   Otherwise set to FALSE (or 'undef')
        #
        # Return values
        #   'undef' on improper arguments or if $name/$language are invalid
        #   Blessed reference to the newly-created object on success

        my ($class, $session, $name, $language, $tempFlag, $check) = @_;

        # Check for improper arguments
        if (! defined $class || ! defined $session || ! defined $name || defined $check) {

            return $axmud::CLIENT->writeImproper($class . '->new', @_);
        }

        if (! $tempFlag) {

            # Check that $name is valid and not already in use by another dictionary
            if (! $axmud::CLIENT->nameCheck($name, 16)) {

                return $axmud::CLIENT->writeError(
                    'Registry naming error: invalid name \'' . $name . '\'',
                    $class . '->new',
                );

            } elsif ($axmud::CLIENT->ivExists('dictHash', $name)) {

                return $axmud::CLIENT->writeError(
                    'Registry naming error: dictionary \'' . $name . '\' already exists',
                    $class . '->new',
                );
            }

            # If $language was specified, check it's not too long
            if (defined $language) {

                if (! $axmud::CLIENT->nameCheck($language, 16)) {

                    return $axmud::CLIENT->writeError(
                        'Registry naming error: invalid language name \'' . $language . '\'',
                        $class . '->new',
                    );
                }
            }
        }

        # Set the language, if not specified
        if (! defined $language) {

            $language = 'English';
        }

        # Setup
        my $self = {
            _objName                    => $name,
            _objClass                   => $class,
            _parentFile                 => 'dicts',
            _parentWorld                => undef,
            # Many IVs are interconnected, so we mark them all as 'private' to force use of the
            #   accessor methods set_, add_, del_ ...
            _privFlag                   => TRUE,

            # Dictionary IVs
            # --------------

            # A unique name for the dictionary
            name                        => $name,
            # The dictionary uses this language. Can be any string useful to the user, e.g.
            #   'French', 'Francais', 'Franzoesisch'
            language                    => $language,
            # Noun position for this language:
            #   'noun_adj' - typical order is noun-adjective (e.g. French)
            #   'adj_noun' - typical order is adjective-noun (e.g. English)
            nounPosn                    => 'adj_noun',

            # NB In this function, 'standard term' refers to a key in a hash that never changes,
            #   regardless of the dictionary's language.
            # For example, the keys in $self->timeHash are always the standard terms second,
            #   minute, hour, day, week, month, year, decade, century, millennium;
            #   the corresponding values show the equivalent words in the dictionary's language
            # In this function, standard terms are not enclosed by single quotes

            # Articles/conjunctions
            # ---------------------

            # Definite articles used in the dictionary's language
            definiteList                => [
                'the',
            ],
            # Indefinite articles used in the dictionary's language
            indefiniteList              => [
                'a',
                'an',
            ],
            # Words for 'and' in the dictionary's language
            andList                     => [
                'and',
                'also',
            ],
            # Words for 'or' in the dictionary's language
            orList                      => [
                'or',
            ],

            # Numbers / time
            # --------------

            # Hash of numbers, transforming a word or phrase in the dictionary's language into a
            #   number. Hash in the form
            #       $numberHash{word_or_phrase} = number
            #   e.g. $numberHash{'two'} = 2
            #   e.g. $numberHash{'half of'} = 0.5
            # Indeterminate words or phrases, like 'some of', are given the value -1
            #   e.g. $numberHash{'some of'} = -1
            numberHash                  => {
                # Zeroes
                'no'                    => 0,
                'zero'                  => 0,
                'none'                  => 0,
                'nil'                   => 0,
                # Named numbers
                'one'                   => 1,
                'two'                   => 2,
                'three'                 => 3,
                'four'                  => 4,
                'five'                  => 5,
                'six'                   => 6,
                'seven'                 => 7,
                'eight'                 => 8,
                'nine'                  => 9,
                'ten'                   => 10,
                'eleven'                => 11,
                'twelve'                => 12,
                'thirteen'              => 13,
                'fourteen'              => 14,
                'fifteen'               => 15,
                'sixteen'               => 16,
                'seventeen'             => 17,
                'eighteen'              => 18,
                'nineteen'              => 19,
                'twenty'                => 20,
                'thirty'                => 30,
                'forty'                 => 40,
                'fifty'                 => 50,
                'sixty'                 => 60,
                'seventy'               => 70,
                'eighty'                => 80,
                'ninenty'               => 90,
                'hundred'               => 100,
                # Fractions
                'half'                  => 0.5,
                'half of'               => 0.5,
                'third'                 => 0.33,
                'third of'              => 0.33,
                'quarter'               => 0.25,
                'quarter of'            => 0.25,
                # Indeterminate numbers
                'fraction'              => -1,
                'fraction of'           => -1,
                'many'                  => -1,
                'many of'               => -1,
                'number'                => -1,
                'number of'             => -1,
                'part'                  => -1,
                'part of'               => -1,
                'several'               => -1,
                'several of'            => -1,
                'some'                  => -1,
                'some of'               => -1,
            },

            # Hashes of time words, transforming a standard term into the equivalent. Hashes in the
            #   form
            #       $hash{standard_term} = word_in_language
            #   e.g. $timeHash{'hour'} = 'heure'       # (French)
            timeHash                    => {
                'second'                => 'second',
                'minute'                => 'minute',
                'hour'                  => 'hour',
                'day'                   => 'day',
                'week'                  => 'week',
                'month'                 => 'month',
                'year'                  => 'year',
                'decade'                 => 'decade',
                'century'               => 'century',
                'millennium'            => 'millennium',
            },
            timePluralHash              => {
                'second'                => 'seconds',
                'minute'                => 'minutes',
                'hour'                  => 'hours',
                'day'                   => 'days',
                'week'                  => 'weeks',
                'month'                 => 'months',
                'year'                  => 'years',
                'decade'                => 'decades',
                'century'               => 'centuries',
                'millennium'            => 'millennia',
            },
            # The same hashes, reversed
            reverseTimeHash             => {},  # Set below
            reverseTimePluralHash       => {},  # Set below

            # Hashes of time phrases, transforming a clock time in the dictionary's language
            #   (e.g. 'twenty past ten in the morning') into a digital time
            # Hash transforming a phrase into 0 for a.m. and 1 for p.m., in the form
            #   $clockDayHash{phrase} = number
            clockDayHash                => {
                'in the morning'        => 0,
                'in the afternoon'      => 1,
                'in the evening'        => 1,
                'at night'              => 1,
            },
            # Hash transforming a phrase into an hour of the clock, in the form
            #   $clockHourHash{phrase} = number
            clockHourHash               => {
                'midnight'              => 0,
                'one'                   => 1,
                'two'                   => 2,
                'three'                 => 3,
                'four'                  => 4,
                'five'                  => 5,
                'six'                   => 6,
                'seven'                 => 7,
                'eight'                 => 8,
                'nine'                  => 9,
                'ten'                   => 10,
                'eleven'                => 11,
                'twelve'                => 12,
                'midday'                => 12,
                'one o\'clock'          => 1,
                'two o\'clock'          => 2,
                'three o\'clock'        => 3,
                'four o\'clock'         => 4,
                'five o\'clock'         => 5,
                'six o\'clock'          => 6,
                'seven o\'clock'        => 7,
                'eight o\'clock'        => 8,
                'nine o\'clock'         => 9,
                'ten o\'clock'          => 10,
                'eleven o\'clock'       => 11,
                'twelve o\'clock'       => 12,
            },
            # Hash transforming a phrase into an minute past the hour. Negative values establish
            #   minutes past the previous hour, so 'quarter to eleven' produces hour = 11,
            #   minutes = -45, so time = 10:45. Hash in the form
            #       $clockMinuteHash{phrase} = number
            clockMinuteHash             => {
                'exactly'               => 0,
                'five past'             => 5,
                'five-past'             => 5,
                'ten past'              => 10,
                'ten-past'              => 10,
                'quarter past'          => 15,
                'quarter-past'          => 15,
                'twenty past'           => 20,
                'twenty-past'           => 20,
                'twenty five past'      => 25,
                'twenty-five past'      => 25,
                'twenty-five-past'      => 25,
                'half past'             => 30,
                'half-past'             => 30,
                'twenty five to'        => -35,
                'twenty-five to'        => -35,
                'twenty-five-to'        => -35,
                'twenty to'             => -40,
                'twenty-to'             => -40,
                'quarter to'            => -45,
                'quarter-to'            => -45,
                'ten to'                => -50,
                'ten-to'                => -50,
                'five to'               => -55,
                'five-to'               => -55,
            },

            # Portable object types
            # ---------------------

            # Lists of portable model object types (things which can, in theory, be picked up)
            # All portables are given a type, as a guide to what sort of object they might be
            # Portable types used by Axmud are
            #   torch       (anything that casts light with fire)
            #   lamp        (anything that casts light by being turned on)
            #   match       (anything that can light a torch or start a fire)
            #   key         (anything that unlocks something)
            #   map         (any kind of map)
            #   book        (any readable object, with multiple pages)
            #   toy         (any kind of toy or game)
            #   paper       (any readable object, with a single page)
            #   corpse      (any word for a dead thing)
            #   bodypart    (any word for a piece of dead thing - arms, legs, etc)
            #   sack        (any bag that can hold other things)
            #   box         (any kind of box that can hold things)
            #   container   (anything that's not a bag or a box, that can hold other things)
            #   coin        (any monetary unit)
            #   treasure    (anything which is just valuable, not including money)
            #   jewellery   (valuable items that can be worn)
            #   tool        (lockpicks, crowbars, etc)
            #   instrument  (musical instruments)
            #   spade       (anything for digging)
            #   food        (anything that can be eaten)
            #   drink       (anything non-alcoholic that can be drunk)
            #   alcohol     (anything alcoholic than can be drunk)
            #   medicine    (anything which can be eaten or drunk as a medicine)
            #   potion      (any kind of potion)
            #   poison      (the opposite of medicine)
            #   watch       (any portable thing that tells the time)
            #   cup         (any container which only holds liquids - cups, mugs, vials, etc)
            #   cutlery     (any forks, plates, etc - but not cups)
            #   vehicle     (a car, hoverpod - anything for transportation)
            #   boat        (anything used for transportation on water - can't be picked up, but
            #                   can be moved, so it's a portable)
            #   plane       (anything used for transportation in the air)
            #   rope        (any rope-like thing used for climbing)
            #   collectable (any collectable item)
            #   toy         (any kind of toy)
            #   other       (anything else)
            #
            # Custom types can also be created. ->constPortableTypeList contains the default list of
            #   types, and ->portableTypeList contains the actual list of types for this dictionary
            constPortableTypeList       => [
                'torch',
                'lamp',
                'match',
                'key',
                'map',
                'book',
                'toy',
                'paper',
                'corpse',
                'bodypart',
                'sack',
                'box',
                'container',
                'coin',
                'treasure',
                'jewellery',
                'tool',
                'instrument',
                'spade',
                'food',
                'drink',
                'alcohol',
                'medicine',
                'potion',
                'poison',
                'watch',
                'cup',
                'cutlery',
                'vehicle',
                'boat',
                'plane',
                'rope',
                'collectable',
                'toy',
                'other',
            ],
            portableTypeList            => [],  # Set below

            # Decoration object types
            # -----------------------

            # Lists of decoration model object types (things which can't, in theory, be picked up)
            # All decorations are given a type, as a guide to what sort of object they might be
            # Decoration types used by Axmud are
            #   door        (anything which is openable, and is an exit)
            #   window      (anything which might be openable, and might be an exit)
            #   wall        (any fixed, immovable object resembling a wall, which might be
            #                   climbable)
            #   portal      (any kind of portal)
            #   sign        (any fixed object that is readable)
            #   board       (any fixed object that is interactively readable, e.g. a bulletin board)
            #   light       (any fixed light source)
            #   furniture   (tables, etc)
            #   seat        (anything that can be sat on)
            #   bed         (anything that can be lied on)
            #   fire        (any fire object)
            #   bin         (any container from which things don't return)
            #   container   (any other kind of container)
            #   cart        (any container which can be moved, usually by pushing it)
            #   ladder      (any immovable, climable object)
            #   button      (anything that can be pushed)
            #   lever       (anything that can be pulled)
            #   clock       (any decoration that tells the time)
            #   machine     (any kind of static machine, e.g. a lottery machine)
            #   hook        (any object to which things, like ropes, can be tied)
            #   tree        (any kind of large plant, that could potentially be climbed)
            #   plant       (any other kind of plant)
            #   fountain    (any kind of water source)
            #   monument    (any kind of monument or statue)
            #   other       (any other object)
            #
            # Custom types can also be created. ->constDecorationTypeList contains the default list
            #   of types, and ->decorationTypeList contains the actual list of types for this
            #   dictionary
            constDecorationTypeList     => [
                'door',
                'window',
                'wall',
                'portal',
                'sign',
                'board',
                'light',
                'furniture',
                'seat',
                'bed',
                'fire',
                'bin',
                'container',
                'cart',
                'ladder',
                'button',
                'lever',
                'clock',
                'machine',
                'hook',
                'tree',
                'plant',
                'fountain',
                'monument',
                'other',
            ],
            decorationTypeList          => [],  # Set below

            # Object classes
            # --------------

            # Hashes of objects, transforming an object (e.g. 'spider') into a word which roughly
            #   corresponds to a class of model object (e.g. 'creature').
            # Guilds, races and adjectives are treated as separate classes even though there is no
            #   'guild' or 'race' model object, and certainly no 'adj' model object.
            # Hashes in the form
            #   $hash{word} = world_model_category
            guildHash                   => {
                'adventurer'            => 'guild',
                'bard'                  => 'guild',
                'cleric'                => 'guild',
                'fighter'               => 'guild',
                'thief'                 => 'guild',
                'wizard'                => 'guild',
            },
            raceHash                    => {
                'centaur'               => 'race',
                'dwarf'                 => 'race',
                'faery'                 => 'race',
                'fairy'                 => 'race',
                'giant'                 => 'race',
                'goblin'                => 'race',
                'gnome'                 => 'race',
                'halfling'              => 'race',
                'hobgoblin'             => 'race',
                'human'                 => 'race',
                'kobold'                => 'race',
                'minotaur'              => 'race',
                'ogre'                  => 'race',
                'orc'                   => 'race',
                'troll'                 => 'race',
            },
            weaponHash                  => {
                'sword'                 => 'weapon',
                'axe'                   => 'weapon',
                'club'                  => 'weapon',
                'mace'                  => 'weapon',
                'dagger'                => 'weapon',
                'knife'                 => 'weapon',
                'wand'                  => 'weapon',
                'staff'                 => 'weapon',
                'stick'                 => 'weapon',
            },
            armourHash                  => {
                'armour'                => 'armour',
                'chain-mail'            => 'armour',
                'gauntlet'              => 'armour',
                'helm'                  => 'armour',
                'helmet'                => 'armour',
                'jacket'                => 'armour',
                'mail'                  => 'armour',
            },
            garmentHash                 => {
                'hat'                   => 'garment',
                'coat'                  => 'garment',
                'scarf'                 => 'garment',
                'shoe'                  => 'garment',
                'boot'                  => 'garment',
                'shirt'                 => 'garment',
                'jumper'                => 'garment',
                'trousers'              => 'garment',
                'shorts'                => 'garment',
                'dress'                 => 'garment',
                'pants'                 => 'garment',
                'socks'                 => 'garment',
                'cloak'                 => 'garment',
                'veil'                  => 'garment',
            },
            sentientHash                => {
                'guard'                 => 'sentient',
                'lookout'               => 'sentient',
                'sentry'                => 'sentient',
                'warrior'               => 'sentient',
                'man'                   => 'sentient',
                'woman'                 => 'sentient',
                'youth'                 => 'sentient',
                'child'                 => 'sentient',
                'baby'                  => 'sentient',
                'priest'                => 'sentient',
                'farmer'                => 'sentient',
                'ghost'                 => 'sentient',
                'beggar'                => 'sentient',
            },
            creatureHash                => {
                'rabbit'                => 'creature',
                'rat'                   => 'creature',
                'dog'                   => 'creature',
                'cat'                   => 'creature',
                'fish'                  => 'creature',
                'chicken'               => 'creature',
                'hen'                   => 'creature',
                'cow'                   => 'creature',
                'bull'                  => 'creature',
                'horse'                 => 'creature',
            },
            portableHash                => {
                'arm'                   => 'portable',
                'backpack'              => 'portable',
                'bag'                   => 'portable',
                'boat'                  => 'portable',
                'book'                  => 'portable',
                'box'                   => 'portable',
                'coin'                  => 'portable',
                'corpse'                => 'portable',
                'foot'                  => 'portable',
                'game'                  => 'portable',
                'guidebook'             => 'portable',
                'hand'                  => 'portable',
                'head'                  => 'portable',
                'key'                   => 'portable',
                'lamp'                  => 'portable',
                'leg'                   => 'portable',
                'map'                   => 'portable',
                'note'                  => 'portable',
                'notebook'              => 'portable',
                'paper'                 => 'portable',
                'parchment'             => 'portable',
                'potion'                => 'portable',
                'remains'               => 'portable',
                'rope'                  => 'portable',
                'sack'                  => 'portable',
                'shovel'                => 'portable',
                'spade'                 => 'portable',
                'torch'                 => 'portable',
                'toy'                   => 'portable',
                'wagon'                 => 'portable',
            },
            decorationHash              => {
                'banner'                => 'decoration',
                'bed'                   => 'decoration',
                'bench'                 => 'decoration',
                'bin'                   => 'decoration',
                'board'                 => 'decoration',
                'box'                   => 'decoration',
                'cart'                  => 'decoration',
                'case'                  => 'decoration',
                'chain'                 => 'decoration',
                'chair'                 => 'decoration',
                'chest'                 => 'decoration',
                'container'             => 'decoration',
                'cupboard'              => 'decoration',
                'door'                  => 'decoration',
                'doorway'               => 'decoration',
                'dustbin'               => 'decoration',
                'fence'                 => 'decoration',
                'fire'                  => 'decoration',
                'fireplace'             => 'decoration',
                'fountain'              => 'decoration',
                'furniture'             => 'decoration',
                'gate'                  => 'decoration',
                'gateway'               => 'decoration',
                'hearth'                => 'decoration',
                'hook'                  => 'decoration',
                'ladder'                => 'decoration',
                'light'                 => 'decoration',
                'machine'               => 'decoration',
                'monument'              => 'decoration',
                'notice'                => 'decoration',
                'plant'                 => 'decoration',
                'portal'                => 'decoration',
                'poster'                => 'decoration',
                'sign'                  => 'decoration',
                'signpost'              => 'decoration',
                'staircase'             => 'decoration',
                'stairs'                => 'decoration',
                'statue'                => 'decoration',
                'steps'                 => 'decoration',
                'stool'                 => 'decoration',
                'table'                 => 'decoration',
                'tree'                  => 'decoration',
                'vortex'                => 'decoration',
                'window'                => 'decoration',
                'wall'                  => 'decoration',
                'water'                 => 'decoration',
                'wheelbarrow'           => 'decoration',
            },
            adjHash                     => {
                'big'                   => 'adj',
                'huge'                  => 'adj',
                'small'                 => 'adj',
                'tiny'                  => 'adj',
                'high'                  => 'adj',
                'low'                   => 'adj',
                'fat'                   => 'adj',
                'thin'                  => 'adj',
                'clean'                 => 'adj',
                'dirty'                 => 'adj',
                'hidden'                => 'adj',
                'open'                  => 'adj',
                'closed'                => 'adj',
                'locked'                => 'adj',
                'unlocked'              => 'adj',
                'good'                  => 'adj',
                'evil'                  => 'adj',
            },

            # Portable/decoration types
            # -------------------------

            # Hash of portable/decoration types, transforming every key in ->portableHash and
            #   ->decorationHash into its portable/decoration type (one of the values stored in
            #   ->portableTypeList or ->decorationTypeList).
            # Hashes in the form
            #   $hash{word} = portable_or_decoration_type
            portableTypeHash            => {
                'arm'                   => 'bodypart',
                'backpack'              => 'backpack',
                'bag'                   => 'bag',
                'beer'                  => 'beer',
                'boat'                  => 'boat',
                'book'                  => 'book',
                'box'                   => 'box',
                'coin'                  => 'coin',
                'corpse'                => 'corpse',
                'foot'                  => 'bodypart',
                'game'                  => 'toy',
                'guidebook'             => 'book',
                'hand'                  => 'bodypart',
                'head'                  => 'bodypart',
                'key'                   => 'key',
                'lamp'                  => 'lamp',
                'leg'                   => 'bodypart',
                'match'                 => 'match',
                'map'                   => 'map',
                'note'                  => 'paper',
                'notebook'              => 'book',
                'paper'                 => 'paper',
                'parchment'             => 'paper',
                'potion'                => 'potion',
                'remains'               => 'corpse',
                'rope'                  => 'rope',
                'sack'                  => 'sack',
                'shovel'                => 'spade',
                'spade'                 => 'spade',
                'torch'                 => 'torch',
                'toy'                   => 'toy',
                'wagon'                 => 'vehicle',
            },
            decorationTypeHash          => {
                'banner'                => 'sign',
                'bed'                   => 'bed',
                'bench'                 => 'seat',
                'bin'                   => 'bin',
                'board'                 => 'decoration',
                'box'                   => 'container',
                'cart'                  => 'cart',
                'case'                  => 'container',
                'chain'                 => 'ladder',
                'chair'                 => 'seat',
                'chest'                 => 'container',
                'container'             => 'container',
                'cupboard'              => 'container',
                'door'                  => 'door',
                'doorway'               => 'door',
                'dustbin'               => 'bin',
                'fence'                 => 'wall',
                'fire'                  => 'fire',
                'fireplace'             => 'fire',
                'fountain'              => 'fountain',
                'furniture'             => 'furniture',
                'gate'                  => 'door',
                'gateway'               => 'door',
                'hearth'                => 'fire',
                'hook'                  => 'hook',
                'ladder'                => 'ladder',
                'light'                 => 'light',
                'machine'               => 'machine',
                'monument'              => 'monument',
                'notice'                => 'sign',
                'plant'                 => 'plant',
                'portal'                => 'portal',
                'poster'                => 'sign',
                'sign'                  => 'sign',
                'signpost'              => 'sign',
                'staircase'             => 'ladder',
                'stairs'                => 'ladder',
                'statue'                => 'monument',
                'steps'                 => 'ladder',
                'stool'                 => 'seat',
                'table'                 => 'furniture',
                'tree'                  => 'tree',
                'vortex'                => 'window',
                'wall'                  => 'wall',
                'water'                 => 'other',
                'wheelbarrow'           => 'wheelbarrow',
                'window'                => 'window',
            },

            # Plurals
            # -------

            # Hash that transforms a plural ending commonly found in the dictionary's language into
            #   a singular ending. Hash in the form
            #       $pluralEndingHash{plural_ending_regex} = singular_ending_string
            #   e.g. $pluralEndingHash{'ies$'} = 'y'
            # NB The key is a regex, because it's used in an s// substitution
            # NB Endings are processed in order of length (longest key first)
            pluralEndingHash            => {
                's$'                    => '',
                'ies$'                  => 'y',
                'ves$'                  => 'f',
                'ches$'                 => 'ch',
                'shes$'                 => 'sh',
                'esses$',               => 'ess',
            },
            # Hash that transforms a singular ending in the dictionary's language into a commonly
            #   found plural ending.
            # When converting a singular word into a plural, if none of the keys in this hash match
            #   the singular word, the value corresponding to the key '' is added to the word,
            #   (e.g. 'orc' -> 'orcs')
            # Hash in the form
            #   $pluralEndingHash{singular_ending_regex} = plural_ending_string
            # e.g. $pluralEndingHash{'y$'} = 'ies'
            # NB The key is a regex, because it's used in an s// substitution
            # NB Endings are processed in order of length (longest key first)
            reversePluralEndingHash     => {
                ''                      => 's',
                'y$'                    => 'ies',
                'f$'                    => 'ves',
                'ch$'                   => 'ches',
                'sh$'                   => 'shes',
                'ess$',                 => 'esses',
            },
            # Hash that deals with exceptions to the above rules, transforming a singular word into
            #   its plural form. Hash in the form
            #       $pluralNounHash{singular} = plural
            #   e.g. $pluralNounHash{'knife'} = 'knives'
            pluralNounHash              => {
                'knife'                 => 'knives',
                'staff'                 => 'staves',
                'man'                   => 'men',
                'woman'                 => 'women',
                'child'                 => 'children',
                'remains'               => 'remains',
            },
            # Hash that deals with exceptions to the above rules, transforming a plural word into
            #   its singular form. Hash in the form
            #       $pluralNounHash{singular} = plural
            #   e.g. $pluralNounHash{'knife'} = 'knives'
            reversePluralNounHash       => {
                'knives'                => 'knife',
                'staves'                => 'staff',
                'men'                   => 'man',
                'women'                 => 'woman',
                'children'              => 'child',
                'remains'               => 'remains',
            },

            # Adjective declension
            # --------------------

            # Hashes transforming an adjective into its declined form (might be useful in some
            #   languages, but not used in English. For languages that use declined plural
            #   adjectives, simply treat them as normal declined adjectives)
            #
            # Hash transforming a declined adjective ending commonly found in the dictionary's
            #   language into the equivalent non-declined ending. Hash in the form
            #       $adjEndingHash{declined_ending_regex} = replacement_ending_string
            #   e.g. $adjEndingHash{'en$'} = 'e'   (from German)
            # NB The key is a regex, because it's used in an s// substitution
            # NB Endings are processed in order of length (longest key first)
            adjEndingHash               => {
#               'declined_ending$'      => 'replacement_ending'
            },
            # Hash transforming a non-declined adjective ending commonly found in the dictionary's
            #   language into the equivalent declined ending. Hash in the form
            #       $reverseAdjEndingHash{non_declined_ending_regex} = replacement_ending_string
            #   e.g. $reverseAdjEndingHash{'e$'} = 'en'   (from German)
            reverseAdjEndingHash        => {
#               'non_declined_ending$'  => 'replacement_ending'
            },
            # Hash that deals with exceptions to the above rules, transforming a non-declined
            #   adjective into its declined form. Hash in the form
            #       $declinedAdjHash{non_declined_word_regex} = declined_word_string
            #   e.g. $declinedAdjHash{'beau'} = 'belle'
            declinedAdjHash             => {
#               'non_declined_adj'      => 'declined adjective',
            },
            # Hash that deals with exceptions to the above rules, transforming a declined
            #   adjective into its non-declined form. Hash in the form
            #       $declinedAdjHash{declined_word_regex} = non_declined_word_string
            # e.g. $declinedAdjHash{'belle'} = 'beau'
            reverseDeclinedAdjHash      => {
#               'non_declined_adj'      => 'declined adjective',
            },

            # Pseudo-nouns / pseudo-objects / pseudo-adjectives
            # -------------------------------------------------

            # Hash of groups of words which represent a single noun (often used in constructions
            #   containing several nouns, e.g. 'wizard teacher' or grammatical constructions like
            #   'conan the barbarian' or 'defender of honour'. These groups are called
            #   'pseudo-nouns'. Pseudo-nouns are regexes.
            # Hash in the form
            #   $pseudoNounHash{phrase_regex} = replacement_noun_string
            pseudoNounHash              => {
#               'regex'                 => 'replacement ',
            },
            # Hash of groups of words which represent a single adjective. These groups are called
            #   pseudo-adjectives. Pseudo-adjectives are regexes.
            # Hash in the form
            #   $pseudoAdjHash{phrase_regex} = replacement_adjective_string
            pseudoAdjHash               => {
#               'regex'                 => 'replacement ',
            },
            # When Axmud tries to parse a line of text containing objects, the first thing it does
            #   is to search the line for 'pseudo-objects' - strings that should be reduced to
            #   something else, at the beginning of parsing
            # For example, the line 'He-man, master of the universe is here' would normally be
            #   interpreted as two objects, because of the comma ('he-man' and 'master of the
            #   universe').
            # You can prevent such lines of text from confusing the parser by defining the string
            #   'He-man, master of the universe is here' as a pseudo-object, which is replaced by
            #   another string. Pseudo-objects are regexes.
            #
            # Hash in the form
            #   $pseudoObjHash{phrase_regex} = replacement_string
            #       e.g. $pseudoObjHash{'He-man, master of the universe'} = 'he-man'
            # (In this example, the replacement string might be 'he-man', so the line of text would
            #   become 'He-man is here' BEFORE the parser does any serious work on it)
            #       e.g. $pseudoObjHash{'a big pile of nothing'} = ''
            # (In this example, the replacement string is an empty string, so the parser ignores
            #   the text 'a big pile of nothing' altogether
            #
            # NB Pseudo-object replacement strings can be several words, perhaps 'cute little bunny'
            #   - but pseudo-noun replacement strings should be a single noun, perhaps 'bunny' and
            #   pseudo-adjective replacement strings should be a single adjective, perhaps 'cute'
            pseudoObjHash               => {
#               'regex'                 => 'replacement ',
            },

            # Other words
            # -----------

            # Hash of words (doesn't matter if they're recognised nouns/adjectives, or not) which
            #   mark an object as being 'dead'. The list must contain both singular and plural
            #   forms (e.g. 'corpses' as well as 'corpse')
            # Hash in the form
            #   $deathWordHash{'word'} = undef
            deathWordHash               => {
                'corpse'                => undef,
                'corpses'               => undef,
                'dead'                  => undef,
            },
            # Hash of unknown words - those which have been collected by the Locator task but which
            #   haven't been added to the dictionary yet. The words are stored in a hash for quick
            #   retrievel. Hash in the form
            #       $unknownWordHash{'word'} = undef
            unknownWordHash             => {
#               'unknown_word'          => undef,
            },
            # Hash of unknown contents lines which have been collected by the Locator task,
            #   without (or as well as) splitting the lines into single objects. Hash in the form
            #   ->contentsLinesHash{'line_of_text'} = undef
            contentsLinesHash           => {
#               'line_of_text'          => undef,
            },
            # Hash of ignorable words - words which are definitely not nouns or adjectives (nor
            #   pseudo-nouns or pseudo-adjectives) which should not be added to the unknown word
            #   list. This hash should contain commonly-used prepositions and adverbs in the
            #   dictionary's language
            # Hash in the form
            #   $ignoreWordHash('word'} = 'ignore_word'
            ignoreWordHash              => {
                'the'                   => 'ignore_word',
                'a'                     => 'ignore_word',
                'an'                    => 'ignore_word',
                'of'                    => 'ignore_word',
                'from'                  => 'ignore_word',
                'in'                    => 'ignore_word',
                'into'                  => 'ignore_word',
                'on'                    => 'ignore_word',
                'onto'                  => 'ignore_word',
                'above'                 => 'ignore_word',
                'under'                 => 'ignore_word',
                'over'                  => 'ignore_word',
                'underneath'            => 'ignore_word',
                'between'               => 'ignore_word',
                'besides'               => 'ignore_word',
                'in front of'           => 'ignore_word',
                'behind'                => 'ignore_word',
                'opposite'              => 'ignore_word',
                'quickly'               => 'ignore_word',
                'slowly'                => 'ignore_word',
            },

            # Directions
            # ----------

            # Axmud divides all directions (and therefore exit names) into four groups
            # Primary directions are the sixteen compass directions (including 'north', 'northeast'
            #   and 'northnortheast', etc) plus 'up' and 'down'. Axmud assumes that all worlds use
            #   these directions to organise rooms in three-dimensional space
            # Secondary directions are a customisable list of directions commonly found in worlds
            #   using the dictionary's language (words such as 'entrance', 'exit', 'in', 'out', etc)
            # Relative directions are those that change, depending on which way the character is
            #   facing (i.e., from which direction the character entered the room). For example,
            #   Discworld uses exits called 'forward', 'backward', 'left', 'forward-left' and so on;
            #   a single exit in a room might be described as 'forward' if the character entered
            #   from the north, or 'backward' if they entered from the south. Axmud translates
            #   relative directions into primary directions before using them
            # Unrecognised directions are any direction not in the above three lists. Axmud treats
            #   any such direction as an unrecognised direction
            #
            # For example, in a room statement like this:
            #
            #       You are in a boring room.
            #       Obvious exits: north, out, wibble
            #
            # ...we have a primary, secondary and unrecognised direction
            #
            # In a room statement like this:
            #
            #       You are in an exciting room.
            #       Obvious exits: forward, forward-left, backward, out
            #
            # ...we have three relative directions and a secondary direction. If entering from the
            #   south, 'forward' is translated as 'north', 'forward-left' is translated as
            #   'northwest' and 'backward' is translated as 'south'. 'out' is treated like any other
            #   secondary direction
            #
            # Axmud uses 'standard' primary directions internally:
            #   nort northnortheast northeast eastnortheast east eastsoutheast southeast
            #   southsoutheast south southsouthwest southwest westsouthwest west westnorthwest
            #   northwest northnorthwest up down
            # These scalar values never change and are available in GA::Client->constPrimaryDirList,
            #   ->constShortPrimaryDirList and ->constShortPrimaryDirHash
            # Axmud uses the dictionary map these standard values onto custom primary directions in
            #   whichever language the dictionary is using (e.g. mapping the standard 'north' onto
            #   the Spanish 'norte'). If the dictionary's language is English, then the standard
            #   and custom directions (probably) have the same value
            # For an exit, the world model stores both the exit's standard direction and the
            #   corresponding custom direction. The automapper uses the standard direction to decide
            #   how to draw the exit on the map, and uses the custom direction to respond to the
            #   user's commands
            #
            # The dictionary stores both abbreviated and non-abbreviated forms of each primary
            #   direction, but makes no distinction between abbreviated and non-abbreviated forms of
            #   secondary and tertiary directions
            #
            # Primary direction hash - maps the standard primary directions onto the customised
            #   forms for this dictionary's language. Hash in the form
            #       $primaryDirHash{standard_primary_dir} = custom_primary_dir
            primaryDirHash              => {
                north                   => 'north',
                northnortheast          => 'northnortheast',
                northeast               => 'northeast',
                eastnortheast           => 'eastnortheast',
                east                    => 'east',
                eastsoutheast           => 'eastsoutheast',
                southeast               => 'southeast',
                southsoutheast          => 'southsoutheast',
                south                   => 'south',
                southsouthwest          => 'southsouthwest',
                southwest               => 'southwest',
                westsouthwest           => 'westsouthwest',
                west                    => 'west',
                westnorthwest           => 'westnorthwest',
                northwest               => 'northwest',
                northnorthwest          => 'northnorthwest',
                up                      => 'up',
                down                    => 'down',
            },
            # Primary abbreviated direction hash - maps the standard primary directions onto the
            #   customised abbreviated forms for this dictionary's language. Hash in the form
            #       $primaryAbbrevHash{standard_primary_dir} = custom_primary_abbrev_dir
            primaryAbbrevHash           => {
                north                   => 'n',
                northnortheast          => 'nne',
                northeast               => 'ne',
                eastnortheast           => 'ene',
                east                    => 'e',
                eastsoutheast           => 'ese',
                southeast               => 'se',
                southsoutheast          => 'sse',
                south                   => 's',
                southsouthwest          => 'ssw',
                southwest               => 'sw',
                westsouthwest           => 'wsw',
                west                    => 'w',
                westnorthwest           => 'wnw',
                northwest               => 'nw',
                northnorthwest          => 'nnw',
                up                      => 'u',
                down                    => 'd',
            },
            # Primary opposite hash - maps the standard primary directions onto the customised
            #   form of the opposite direction. Hash in the form
            #       $primaryOppHash{standard_primary_dir} = custom_primary_opposite_dir
            # NB If there is more than one possible opposite, separate them with a space,
            #   e.g. 'south out'. If there is no opposite direction, use an empty string.
            primaryOppHash              => {
                north                   => 'south',
                northnortheast          => 'southsouthwest',
                northeast               => 'southwest',
                eastnortheast           => 'westsouthwest',
                east                    => 'west',
                eastsoutheast           => 'westnorthwest',
                southeast               => 'northwest',
                southsoutheast          => 'northnorthwest',
                south                   => 'north',
                southsouthwest          => 'northnortheast',
                southwest               => 'northeast',
                westsouthwest           => 'eastnortheast',
                west                    => 'east',
                westnorthwest           => 'eastsoutheast',
                northwest               => 'southeast',
                northnorthwest          => 'southsoutheast',
                up                      => 'down',
                down                    => 'up',
            },
            # Primary opposite abbreviated hash - maps the standard primary directions onto the
            #   customised form of the opposite direction. Hash in the form
            #      $primaryOppHash{standard_primary_dir} = custom_primary_abbrev_opposite_dir
            # NB If there is more than one possible opposite, separate them with a space,
            #   e.g. 's out'. If there is no abbreviated direction, use an empty string
            primaryOppAbbrevHash        => {
                north                   => 's',
                northnortheast          => 'ssw',
                northeast               => 'sw',
                eastnortheast           => 'wsw',
                east                    => 'w',
                eastsoutheast           => 'wnw',
                southeast               => 'nw',
                southsoutheast          => 'nnw',
                south                   => 'n',
                southsouthwest          => 'nne',
                southwest               => 'ne',
                westsouthwest           => 'ene',
                west                    => 'e',
                westnorthwest           => 'ese',
                northwest               => 'se',
                northnorthwest          => 'sse',
                up                      => 'd',
                down                    => 'u',
            },

            # A customisable list of secondary directions, in an order defined by the user; the
            #   equivalent of GA::Client->constPrimaryDirList, but this list can be modified
            # Any possible abbreviations are treated as distinct secondary directions
            secondaryDirList            => [
                'in',
                'out',
                'entrance',
                'exit',
                'steps',
                'lift',
                'hole',
                'gap',
                'crack',
                'opening',
                'gate',
                'gateway',
                'door',
                'doorway',
                'portal',
                'vortex',
            ],
            # Secondary direction hash - a list of recognised secondary directions (including any
            #   possible abbreviations). To be compatible with $self->primaryDirHash, the key and
            #   corresponding value are the same
            #       ->secondaryDirHash{secondary_dir} = secondary_dir
            secondaryDirHash            => {
                'in'                    => 'in',
                'out'                   => 'out',
                'entrance'              => 'entrance',
                'exit'                  => 'exit',
                'steps'                 => 'steps',
                'lift'                  => 'lift',
                'hole'                  => 'hole',
                'gap'                   => 'gap',
                'crack'                 => 'crack',
                'opening'               => 'opening',
                'gate'                  => 'gate',
                'gateway'               => 'gateway',
                'door'                  => 'door',
                'doorway'               => 'doorway',
                'portal'                => 'portal',
                'vortex'                => 'vortex',
            },
            # Secondary abbreviated direction hash - maps the recognised secondary directions onto
            #   customised abbreviated forms for this dictionary's language. If there's no
            #   abbreviated form of the direction, the value of the key-value pair should be
            #   'undef'. Hash in the form
            #       $primaryAbbrevHash{recongised_secondary_dir} = secondary_abbrev_dir
            #       $primaryAbbrevHash{recongised_secondary_dir} = undef
            secondaryAbbrevHash         => {
                'in'                    => undef,       # Default, no abbreviated form
                'out'                   => undef,
                'entrance'              => undef,
                'exit'                  => undef,
                'steps'                 => undef,
                'lift'                  => undef,
                'hole'                  => undef,
                'gap'                   => undef,
                'crack'                 => undef,
                'opening'               => undef,
                'gate'                  => undef,
                'gateway'               => undef,
                'door'                  => undef,
                'doorway'               => undef,
                'portal'                => undef,
                'vortex'                => undef,
            },
            # Secondary opposite directions - maps the customised secondary directions onto its
            #   assumed opposite direction, if any (or onto an empty string if not)
            #   Hash in the form
            #       $secondaryOppHash{custom_secondary_dir} = custom_secondary_opposite_dir
            # NB If there is more than one possible opposite, separate them with a space,
            #   e.g. 'south out'. If there is no opposite direction, use an empty string.
            secondaryOppHash            => {
                'in'                    => 'out',
                'out'                   => 'in',
                'entrance'              => 'exit out',
                'exit'                  => 'entrance in',
                'steps'                 => 'steps',
                'lift'                  => 'lift',
                'gate'                  => 'gate',
                'gateway'               => 'gateway',
                'door'                  => 'door',
                'doorway'               => 'doorway',
                'hole'                  => 'hole out',
                'gap'                   => 'gap out',
                'crack'                 => 'crack out',
                'opening'               => 'opening out',
                'portal'                => 'portal out',
                'vortex'                => 'vortex out',
            },
            # Secondary opposite abbreviated hash - maps the recognised secondary directions onto
            #   the customised form of the opposite direction. Hash in the form
            #       $primaryOppHash{standard_primary_dir} = custom_primary_abbrev_opposite_dir
            # NB If there is more than one possible opposite, separate them with a space,
            #   e.g. 'south out'. If there is no abbreviated direction, use an empty string
            secondaryOppAbbrevHash      => {
                'in'                    => '',
                'out'                   => '',
                'entrance'              => '',
                'exit'                  => '',
                'steps'                 => '',
                'lift'                  => '',
                'gate'                  => '',
                'gateway'               => '',
                'door'                  => '',
                'doorway'               => '',
                'hole'                  => '',
                'gap'                   => '',
                'crack'                 => '',
                'opening'               => '',
                'portal'                => '',
                'vortex'                => '',
            },
            # Secondary auto-allocatable directions. Maps a secondary direction onto a standard
            #   primary direction, so that the automapper can automatically allocate it (e.g. if a
            #   newly-encountered room contains a 'portal' exit, the automapper can automatically
            #   allocate it to 'down', if that's what the user wants)
            # For each key-value pair, if the value is 'undef', the secondary direction in the key
            #   is not auto-allocated
            secondaryAutoHash           => {
                'in'                    => undef,
                'out'                   => undef,
                'entrance'              => undef,
                'exit'                  => undef,
                'steps'                 => undef,
                'lift'                  => undef,
                'gate'                  => undef,
                'gateway'               => undef,
                'door'                  => undef,
                'doorway'               => undef,
                'hole'                  => undef,
                'gap'                   => undef,
                'crack'                 => undef,
                'opening'               => undef,
                'portal'                => undef,
                'vortex'                => undef,
            },

            # Relative directions, which are translated into the eight cardinal directions,
            #   depending on the direction of entry
            # One or more relative directions can be defined. For any relative direction that's
            #   defined, the opposite should probably be defined too. If no relative directions are
            #   defined, then Axmud doesn't use relative directions
            # If the direction of entry into a room is not known, Axmud uses the direction of the
            #   first incoming exit that's not itself a relative direction; if that too fails, the
            #   direction of entry is taken to be 'south'
            # Keys in the hash are integers in the range 0-7. Axmud help files describe them as
            #   'slots'. 0 represents 'forward', i.e. movement in the same direction as the
            #   direction of entry. Then we move clockwise, so 1 represents 'forward-right',
            #   2 'right', 3 'backward-right', 4 'backward', 5 'backward-left', 6 'left',
            #   7 'forward-left'
            # A key's corresponding value is the relative direction, e.g.
            #   $relativeDirHash{4} = 'backward'
            relativeDirHash             => {},
            # Corresponding hash of abbreviated relative directions, for example
            #   $relativeAbbrevHash{4] = 'bw'
            relativeAbbrevHash          => {},

            # Speedwalk directions
            # --------------------

            # Hash of speedwalking characters (lower-case letters in range a-z, non-Latin alphabets
            #   acceptable) and their corresponding movement commands, which can be standard primary
            #   directions (one of the items in GA::Client->constPrimaryDirList) or any other type
            #   of movement command
            # When interpreting speedwalk commands, GA::Session refers to this hash. If the key's
            #   corresponding value is a standard primary direction, this dictionary is consulted to
            #   provide the corresponding custom primary direction. Otherwise, GA::Session assumes
            #   the key's corresponding value is a valid movement command (probably representing an
            #   exit in the room), and processes it as such
            speedDirHash                => {
                'n'                     => 'north',
                's'                     => 'south',
                'e'                     => 'east',
                'w'                     => 'west',
                'u'                     => 'up',
                'd'                     => 'down',
                'l'                     => 'look',
                't'                     => 'northwest',
                'y'                     => 'northeast',
                'g'                     => 'southwest',
                'h'                     => 'southeast',
            },
            # Hash of speedwalking modifier characters (upper-case letters in range A-Z, non-Latin
            #   alphabets acceptable) and their corresponding standard commands (keys in
            #   GA::Cage::Cmd->cmdHash, e.g. 'go', 'fly', 'sail', 'open_dir', 'unlock_dir' etc)
            # The cage specifies a replacement command for each standard command (the replacement
            #   command can be modified by the user). The replacement is usually in the form
            #   'go direction', 'fly direction', 'sail direction'. There are also non-movement
            #   standard commands like 'open_dir' and 'unlock_dir'; their replacements are usually
            #   in the form 'open direction door' and 'unlock direction door'
            # In the speedwalk command, the modifier character must be followed by a speedwalking
            #   character (e.g. 'Ue', representing 'unlock east door'). The GA::Session processes
            #   the replacement command, substituting the word 'direction' for the speedwalking
            #   character (e.g. standard command 'unlock direction door' becomes 'unlock east door')
            # If the standard command is a movement command (exists in GA::Cage::Cmd->moveCmdList),
            #   GA::Session processes it as a movement command; otherwise it is processed as a
            #   non-movement command
            speedModifierHash           => {
                # Movement commands
                'G'                     => 'go_dir',
                'N'                     => 'run',
                'A'                     => 'walk',
                'F'                     => 'fly',
                'W'                     => 'swim',
                'V'                     => 'dive',
                'S'                     => 'sail',
                'I'                     => 'ride',
                'D'                     => 'drive',
                'R'                     => 'creep',
                'E'                     => 'sneak',
                'Q'                     => 'squeeze',
                # Non-movement commands
                'O'                     => 'open_dir',
                'C'                     => 'close_dir',
                'K'                     => 'unlock',
                'L'                     => 'lock',
                'P'                     => 'pick',
                'B'                     => 'break',
            },

            # Combined hashes
            # ---------------

            # Combined hash of recognised nouns, in the form
            #   $combNounHash{noun} = type
            # ...where 'type' corresponds the name of the hash that stores it
            #   e.g. $combNounHash{'hat'} = garment    (corresponds to $self->garmentHash)
            combNounHash                => {},      # Set below
            # Combined hash of recognised adjectives, in the form
            #   $combAdjHash{adjective} = type
            # ...where 'type' corresponds the name of the hash that stores it
            #   e.g. $combAdjHash{'big'} = 'adj'      (corresponds to $self->adjHash)
            combAdjHash                 => {},      # Set below
            # Combined hash of customised directions, in the form
            #   $combDirHash{custom_direction} = direction_type
            # ...where 'direction_type' is one of 'primaryDir', 'primaryAbbrev', 'secondaryDir',
            #   'secondaryAbbrev', 'relativeDir' or 'relativeAbbrev'
            combDirHash                 => {},      # Set below
            # Combined hash of customised opposite directions, in the form
            #   $combOppDirHash{custom_direction} = custom_opposite_direction
            combOppDirHash              => {},      # Set below
            # Combined hash of customised directions, converting the customised direction into the
            #   standard (fixed) form of the primary or secondary direction (relative directions are
            #   not included). Hash in the form
            #   $combRevDirHash{custom_direction} = standard_direction
            combRevDirHash              => {},      # Set below
        };

        # Bless the object into existence
        bless $self, $class;

        # Set up a few IVs based on other IVs
        $self->{'portableTypeList'} = [$self->constPortableTypeList];
        $self->{'decorationTypeList'} = [$self->constDecorationTypeList];

        # Create combined hashes (without marking the dictionary file object as having had its data
        #   modified)
        $self->createCombHashes($session, FALSE);

        return $self;
    }

    sub clone {

        # Called by GA::Cmd::CloneWorld->do or CloneDictionary->do
        # Creates a clone of an existing dictionary
        #
        # Expected arguments
        #   $session    - The GA::Session which called this function (not stored as an IV)
        #   $name       - A unique string name for this dictionary (max 16 chars, containing
        #                   A-Za-z0-9_ - 1st char can't be number, non-Latin alphabets acceptable.
        #                   Must not exist as a key in the global hash of reserved names,
        #                   $axmud::CLIENT->constReservedHash)
        #
        # Return values
        #   'undef' on improper arguments or if $name is invalid
        #   Blessed reference to the newly-created object on success

        my ($self, $session, $name, $check) = @_;

        # Check for improper arguments
        if (! defined $session || ! defined $name || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->clone', @_);
        }

        # Check that $name is valid and not already in use by another dictionary
        if (! $axmud::CLIENT->nameCheck($name, 16)) {

            return $axmud::CLIENT->writeError(
                'Registry naming error: invalid name \'' . $name . '\'',
                $self->_objClass . '->clone',
            );

        } elsif ($axmud::CLIENT->ivExists('dictHash', $name)) {

            return $axmud::CLIENT->writeError(
                'Registry naming error: dictionary \'' . $name . '\' already exists',
                $self->_objClass . '->clone',
            );
        }

        # Setup
        my $clone = {
            _objName                    => $name,
            _objClass                   => $self->_objClass,
            _parentFile                 => 'dicts',
            _parentWorld                => undef,
            # Many IVs are interconnected, so we mark them all as 'private' to force use of the
            #   accessor methods set_, add_, del_ ...
            _privFlag                   => TRUE,

            name                        => $name,
            language                    => $self->language,
            nounPosn                    => $self->nounPosn,

            definiteList                => [$self->definiteList],
            indefiniteList              => [$self->indefiniteList],
            andList                     => [$self->andList],
            orList                      => [$self->orList],

            numberHash                  => {$self->numberHash},

            timeHash                    => {$self->timeHash},
            timePluralHash              => {$self->timePluralHash},
            reverseTimeHash             => {$self->reverseTimeHash},
            reverseTimePluralHash       => {$self->reverseTimePluralHash},

            clockDayHash                => {$self->clockDayHash},
            clockHourHash               => {$self->clockHourHash},
            clockMinuteHash             => {$self->clockMinuteHash},

            constPortableTypeList       => [$self->constPortableTypeList],
            portableTypeList            => [$self->portableTypeList],

            constDecorationTypeList     => [$self->constDecorationTypeList],
            decorationTypeList          => [$self->decorationTypeList],

            guildHash                   => {$self->guildHash},
            raceHash                    => {$self->raceHash},
            weaponHash                  => {$self->weaponHash},
            armourHash                  => {$self->armourHash},
            garmentHash                 => {$self->garmentHash},
            sentientHash                => {$self->sentientHash},
            creatureHash                => {$self->creatureHash},
            portableHash                => {$self->portableHash},
            decorationHash              => {$self->decorationHash},
            adjHash                     => {$self->adjHash},

            portableTypeHash            => {$self->portableTypeHash},
            decorationTypeHash          => {$self->decorationTypeHash},

            pluralEndingHash            => {$self->pluralEndingHash},
            reversePluralEndingHash     => {$self->reversePluralEndingHash},
            pluralNounHash              => {$self->pluralNounHash},
            reversePluralNounHash       => {$self->reversePluralNounHash},

            adjEndingHash               => {$self->adjEndingHash},
            reverseAdjEndingHash        => {$self->reverseAdjEndingHash},
            declinedAdjHash             => {$self->declinedAdjHash},
            reverseDeclinedAdjHash      => {$self->reverseDeclinedAdjHash},

            pseudoNounHash              => {$self->pseudoNounHash},
            pseudoAdjHash               => {$self->pseudoAdjHash},
            pseudoObjHash               => {$self->pseudoObjHash},

            deathWordHash               => {$self->deathWordHash},
            unknownWordHash             => {$self->unknownWordHash},
            contentsLinesHash           => {$self->contentsLinesHash},
            ignoreWordHash              => {$self->ignoreWordHash},

            primaryDirHash              => {$self->primaryDirHash},
            primaryAbbrevHash           => {$self->primaryAbbrevHash},
            primaryOppHash              => {$self->primaryOppHash},
            primaryOppAbbrevHash        => {$self->primaryOppAbbrevHash},

            secondaryDirList            => [$self->secondaryDirList],
            secondaryDirHash            => {$self->secondaryDirHash},
            secondaryAbbrevHash         => {$self->secondaryAbbrevHash},
            secondaryOppHash            => {$self->secondaryOppHash},
            secondaryOppAbbrevHash      => {$self->secondaryOppAbbrevHash},
            secondaryAutoHash           => {$self->secondaryAutoHash},

            relativeDirHash             => {$self->relativeDirHash},
            relativeAbbrevHash          => {$self->relativeAbbrevHash},

            speedDirHash                => {$self->speedDirHash},
            speedModifierHash           => {$self->speedModifierHash},

            combNounHash                => {$self->combNounHash},
            combAdjHash                 => {$self->combAdjHash},
            combDirHash                 => {$self->combDirHash},
            combOppDirHash              => {$self->combOppDirHash},
            combRevDirHash              => {$self->combRevDirHash},
        };

        # Bless the cloned object into existence
        bless $clone, $self->_objClass;
        return $clone;
    }

    ##################
    # Methods

    sub createCombHashes {

        # Called by $self->new after the object has been blessed into existence, or by any other
        #   function after they have modified the dictionary's IVs
        # Creates the hashes $self->combNounHash and $self->combAdjHash from scratch
        # Creates the combined direction hashes by calling ->createCombDirHash
        #
        # Expected arguments
        #   $session    - The GA::Session which called this function (perhaps indirectly)
        #   $modifyFlag - Set to TRUE if the dictionary file object should be marked as having had
        #                   its data modified, FALSE otherwise. (Should be FALSE when called by
        #                   $self->new, TRUE when called by any other function)
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $session, $modifyFlag, $check) = @_;

        # Local variables
        my $fileObj;

        # Check for improper arguments
        if (! defined $session || ! defined $modifyFlag || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->createCombHashes', @_);
        }

        # Create the combined noun hash, setting $self->combNounHash and ->overflowNounList
        $self->createCombNounHash($session);

        # Create the combined adjective hash
        $self->createCombAdjHash();

        # Create the combined standard direction hash and list
        $self->createCombDirHash();

        # Set the reversed time hashes
        if ($self->timeHash) {
            $self->{'reverseTimeHash'} = { reverse $self->timeHash };
        } else {
            $self->{'reverseTimeHash'} = {};
        }

        if ($self->timePluralHash) {
            $self->{'reverseTimePluralHash'} = { reverse $self->timePluralHash };
        } else {
            $self->{'reverseTimePluralHash'} = {};
        }

        # Set the dictionary file object's ->modifyFlag, if appropriate
        if ($modifyFlag) {

            $axmud::CLIENT->setModifyFlag(
                $self->_parentFile,
                TRUE,
                $self->_objClass . '->createCombHashes',
            );
        }

        return 1;
    }

    sub createCombNounHash {

        # Called by $self->createCombHashes
        # Creates the combined noun hash, the IV ->combNounHash
        #
        # Expected arguments
        #   $session    - The GA::Session which called $self->createCombHashes (perhaps
        #                   indirectly)
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $session, $check) = @_;

        # Local variables
        my (
            @typeList,
            %hash, %combHash,
        );

        # Check for improper arguments
        if (! defined $session || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->createCombNounHash', @_);
        }

        # Nouns are stored in several hashes. $self->combNounHash attemps to combine them into
        #   a single hash, preserving key-value pairs
        #       e.g. $self->guildHash{'cleric'} = 'guild'
        #       e.g. $self->combNounHash{'cleric'} = 'guild'
        #
        # Each key in $self->combNounHash is a noun; the corresponding value is its type. The
        #   type is a string that's identical to the name of the IV, but with the 'Hash' portion
        #   removed (so ->guildHash becomes 'guild')
        #
        # When a noun appears in multiple hashes, we use the one in the highest-priority hash. The
        #   priority order is
        #       pluralNoun > sentient > creature > portable > decoration > race > guild > weapon
        #           > armour > garment > pseudoNoun

        # Deal with plural nouns...
        %hash = $self->reversePluralNounHash;
        foreach my $key (keys %hash) {

            my $value = $hash{$key};

            # If there's a singular noun that's identical, display a warning
            if (exists $combHash{$key}) {

                $session->writeWarning(
                    'Found plural noun \''.$key.'\' with identical singular noun',
                    $self->_objClass . '->createCombNounHash',
                );

                delete $combHash{$key};

            } else {

                # Temporarily mark this noun as being stored in $self->pluralNounHash
                $combHash{$key} = 'pluralNoun';
            }
        }

        # ...then deal with everything else
        @typeList = (
            'sentient', 'creature', 'portable', 'decoration', 'race', 'guild', 'weapon', 'armour',
            'garment', 'pseudoNoun',
        );

        foreach my $type (@typeList) {

            my $hashName = $type . 'Hash';
            my %thisHash = $self->$hashName;

            foreach my $key (keys %thisHash) {

                my $value = $thisHash{$key};

                if (! exists $combHash{$key}) {

                    # Add to the combined hash
                    $combHash{$key} = $value;
                }
            }
        }

        # Now go through the combined noun hash, dealing with everything that was marked as a
        #   plural noun
        # Work out the singular form of the noun (if possible) and then change the value of the
        #   key-value pair to the type matching that singular noun
        foreach my $key (keys %combHash) {

            if ($combHash{$key} eq 'pluralNoun') {

                # Find the equivalent singular word
                my $singular = $self->ivShow('reversePluralNounHash', $key);
                if (defined $singular) {

                    if (! exists ($combHash{$singular} )) {

                        # The singular form should be in the new combined hash, but it's missing
                        $session->writeWarning(
                            'Combined noun hash is missing the singular form \'' . $singular .
                            '\' of the plural noun \''.$key.'\'',
                            $self->_objClass . '->createCombNounHash',
                        );

                        # Remove this plural noun
                        $self->ivDelete('reversePluralNounHash', $key);

                    } else {

                        # The singular form has already been added to the new combined hash
                        if ($combHash{$key} ne $combHash{$singular}) {

                            # Set the parent hash of the plural noun
                            $combHash{$key} = $combHash{$singular};

                        } else {

                            # If plural and singular are the same word (e.g. sheep), we have a
                            #   problem: the value in the key-value pair is currently set to
                            #   'plural', so it's not a simple matter to find the parent hash
                            # Need to check every hash until we find the right singular word,
                            #   so we can set the right parent hash
                            foreach my $type (@typeList) {

                                my $hashName = $type . 'Hash';

                                if ($self->ivExists($hashName, $key)) {

                                    $combHash{$key} = $type;
                                }
                            }

                            # If the parent hash wasn't found, for some reason...
                            if ($combHash{$key} eq 'pluralNoun') {

                                # ...display a warning
                                $session->writeWarning(
                                    'Found plural noun \'' . $key . '\' with identical singular'
                                    . ' form, but no parent hash',
                                    $self->_objClass . '->createCombNounHash',
                                );

                                # Remove this plural noun
                                $self->ivDelete('reversePluralNounHash', $key);
                                delete $combHash{$key};
                            }
                        }
                    }

                } else {

                    # The plural noun dictionary contains an unrecognised noun. Display a warning
                    $session->writeWarning(
                        'Found plural noun \''.$key.'\' with no parent hash',
                        $self->_objClass . '->createCombNounHash',
                    );

                    # Remove this plural noun
                    $self->ivDelete('reversePluralNounHash', $key);
                    delete $combHash{$key};
                }
            }
        }

        # Combined noun hash complete. Update IVs
        $self->{'combNounHash'} = \%combHash;

        return 1;
    }

    sub createCombAdjHash {

        # Called by $self->createCombHashes
        # Creates the combined adjective hash, the IV ->combAdjHash
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my (
            @typeList,
            %hash, %combHash,
        );

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->createCombAdjHash', @_);
        }

        # Adjectives are stored in three hashes. $self->combAdjHash attemps to combine them into
        #   a single hash, preserving key-value pairs
        #       e.g. $self->adjHash{'big'} = 'adj'
        #       e.g. $self->combAdjHash{'big'} = 'adj'
        #
        # Each key in $self->combAdjHash is a noun; the corresponding value is its type. The
        #   type is a string that's identical to the name of the IV, but with the 'Hash' portion
        #   removed (so ->declinedAdjHash becomes 'declinedAdj')
        #
        # When a noun appears in multiple hashes, we use the one in the highest-priority hash. The
        #   priority order is
        #       declinedAdj > adjective > pseudoAdjective
        @typeList = ('declinedAdj', 'adj', 'pseudoAdj');

        foreach my $type (@typeList) {

            my $hashName = $type . 'Hash';
            my %thisHash = $self->$hashName;

            foreach my $key (keys %thisHash) {

                my $value = $thisHash{$key};

                if (! exists $combHash{$key}) {

                    # Add to the combined hash
                    $combHash{$key} = $value;
                }
            }
        }

        # Combined adjective hash complete. Update IVs
        $self->{'combAdjHash'} = \%combHash;

        return 1;
    }

    sub createCombDirHash {

        # Called by $self->createCombHashes and ->updateOppDirHash
        # Creates (or updates) the three combined direction hashes
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my (
            @typeList, @ivList,
            %combHash, %combOppHash, %combRevHash,
        );

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->createCombDirHash', @_);
        }

        # The values stored in key-value pairs in six hashes are combined, creating three combined
        #   hashes

        # A hash of customised directions, in the form
        #   ->combDirHash{custom_direction} = direction_type
        # ...where 'direction_type' is one of these values:
        @typeList = (
            'primaryDir', 'primaryAbbrev', 'secondaryDir', 'secondaryAbbrev', 'relativeDir',
            'relativeAbbrev',
        );

        foreach my $type (@typeList) {

            my $hashName = $type . 'Hash';
            my %thisHash = $self->$hashName;

            foreach my $value (values %thisHash) {

                # ->secondaryAbbrevHash can have 'undef' values in its key-value pairs, so don't add
                #   those to the combined hash
                # If the customised direction has already been added, don't replace it
                if (defined $value && ! exists $combHash{$value}) {

                    $combHash{$value} = $type;
                }
            }
        }

        # A hash of opposite directions, in the form
        #   ->combOppDirHash{custom_direction} = custom_opposite_direction
        @ivList = (
            'primaryDirHash', 'primaryOppHash',
            'primaryAbbrevHash', 'primaryOppAbbrevHash',
            'secondaryDirHash', 'secondaryOppHash',
            'secondaryAbbrevHash', 'secondaryOppAbbrevHash',
        );

        do {

            my (
                $thisHashName, $oppHashName,
                %thisHash, %oppHash,
            );

            $thisHashName = shift @ivList;
            %thisHash = $self->$thisHashName;
            $oppHashName = shift @ivList;
            %oppHash = $self->$oppHashName;

            foreach my $key (keys %thisHash) {

                my ($value, $oppValue);

                $value = $thisHash{$key};
                $oppValue = $oppHash{$key};

                # ->secondaryAbbrevHash can have 'undef' values in its key-value pairs, so don't add
                #   those to the combined hash
                # ->secondaryOppAbbrevHash can have empty string values in its key-value pairs, so
                #   don't add those either
                # If the customised direction has already been added, don't replace it
                if (defined $value && $value ne '' && ! exists $combOppHash{$value}) {

                    $combOppHash{$value} = $oppValue;
                }
            }

        } until (! @ivList);

        # Need some special code to add relative directions to %combOppHash. The comments in ->new
        #   recommend that if a relative direction is added to $self->relativeDirHash or
        #   ->relativeAbbrevHash, the opposite relative direction is added too, but there's no way
        #   to guarantee the user won't miss one out
        for (my $key = 0; $key < 8; $key++) {

            my ($oppKey, $dir, $oppDir);

            # (Keys in the hash are in the range 0-7, so the opposite of 0 is 4, the opposite of 7
            #   is 3, etc)
            $oppKey = $key + 4;
            if ($oppKey > 7) {

                $oppKey -= 8;
            }

            foreach my $iv ('relativeDirHash', 'relativeAbbrevHash') {

                my ($value, $oppValue);

                $value = $self->ivShow($iv, $key);
                $oppValue = $self->ivShow($iv, $oppKey);

                if (defined $value && $value ne '' && defined $oppValue && $oppValue ne '') {

                    $combOppHash{$value} = $oppValue;
                }
            }
        }

        # A hash of customised directions, in the form
        #   ->combRevDirHash{custom_direction} = standard_direction       (for primary directions)
        #   ->combRevDirHash{recognised_direction} = recognised_direction (for secondary directions)
        @typeList = ('primaryDir', 'primaryAbbrev', 'secondaryDir', 'secondaryAbbrev');
        foreach my $type (@typeList) {

            my $hashName = $type . 'Hash';
            my %thisHash = $self->$hashName;

            foreach my $key (keys %thisHash) {

                my $value = $thisHash{$key};

                # ->secondaryAbbrevHash can have 'undef' values in its key-value pairs, so don't add
                #   those to the combined hash
                # If the customised direction has already been added, don't replace it
                if ($value && (! exists $combRevHash{$value})) {

                    $combRevHash{$value} = $key;
                }
            }
        }

        # Combined hashes complete. Update IVs
        $self->{'combDirHash'} = \%combHash;
        $self->{'combOppDirHash'} = \%combOppHash;
        $self->{'combRevDirHash'} = \%combRevHash;

        return 1;
    }

    sub updateCombNounHash {

        # Called by GA::Cmd::AddWord->do or DeleteWord->do
        # Updates the hash $self->combNounHash after one of the main noun hashes is modified
        #   (this method is hopefully quicker than calling $self->createCombHashes every time a
        #   single key-value pair is changed)
        #
        # Expected arguments
        #   $nounType   - Which type of noun has been changed ('pluralNoun', 'sentient', 'creature',
        #                   'portable', 'decoration', 'race', 'guild', 'weapon', 'armour',
        #                   'garment', 'pseudoNoun')
        #   $addFlag    - TRUE if the key-value pair is to be added to the combined hash; FALSE if
        #                   it is to be removed
        #   $key        - ($addFlag = TRUE) The new key; ($addFlag = FALSE) the key to be removed
        #
        # Optional arguments
        #   $value      - ($addFlag = TRUE) The new value ($addFlag = FALSE) 'undef'
        #
        # Return values
        #   'undef' on improper arguments or if the combined hash isn't modified
        #   1 otherwise

        my ($self, $nounType, $addFlag, $key, $value, $check) = @_;

        # Local variables
        my (
            $newPriority, $oldPriority,
            %priorityHash,
        );

        # Check for improper arguments
        if (! defined $nounType || ! defined $addFlag || ! defined $key || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->updateCombNounHash', @_);
        }

        # Create a hash of priorities, so we can quickly work out what to do with the new key-value
        #   pair
        %priorityHash = (
            'pluralNoun'    => 0,
            'sentient'      => 1,
            'creature'      => 2,
            'portable'      => 3,
            'decoration'    => 4,
            'race'          => 5,
            'guild'         => 6,
            'weapon'        => 7,
            'armour'        => 8,
            'garment'       => 9,
            'pseudoNoun'    => 10,
        );

        # Check that $nounType is valid
        if (! exists $priorityHash{$nounType} ) {

            # Treat this as an improper argument
            return $axmud::CLIENT->writeImproper($self->_objClass . '->updateCombNounHash', @_);
        }

        # If the key-value pair is to be added to the combined hash...
        if ($addFlag) {

            # If it doesn't already exist in the hash, simply add it
            if (! $self->ivExists('combNounHash', $key)) {

                $self->ivAdd('combNounHash', $key, $value);
                return 1;

            # Otherwise work out which key-value pair has priority
            } else {

                $newPriority = $priorityHash{$value};
                $oldPriority = $priorityHash{$self->ivShow('combNounHash', $key)};
                if ($oldPriority < $newPriority) {

                    # New key-value pair takes precedence
                    $self->ivAdd('combNounHash', $key, $value);
                    return 1;

                } else {

                    # Old key-value pair takes precedence; don't change the combined hash
                    return undef;
                }
            }

        # If the key-value pair is to be removed from the combined hash, need to check whether a
        #   noun from a higher-priority hash should replace it
        #
        # If the key-value pair isn't in the combined hash, no changes to make
        } elsif (! $self->ivExists('combNounHash', $key)) {

            return undef;

        } else {

            # Remember the priority of the dictionary hash which contains the key-value pair to be
            #   deleted
            $value = $self->ivShow('combNounHash', $key);
            $newPriority = $priorityHash{$value};

            # Delete the key
            $self->ivDelete('combNounHash', $key);

            # Check the lower-priority dictionary hashes to see if any of them use the same key
            # Reinstate the first key-value pair found
            if ($newPriority == 10) {       # Axmud dictionaries use 11 noun hashes

                # No dictionary hashes with lower priority to check
                return 1;

            } else {

                for (my $count = 1; $count <= 10; $count++) {

                    my $hashName = $nounType . 'Hash';
                    if ($newPriority <= $count && $self->ivExists($hashName, $key)) {

                        # The same key was found in this dictionary hash. Reinstate it into the
                        #   combined hash
                        $value = $self->ivShow($hashName, $key);
                        $self->ivAdd('combNounHash', $key, $value);

                        return 1;
                    }
                }

                # None of the lower-priority dictionary hashes use the same key
                return undef;
            }
        }
    }

    sub updateCombAdjHash {

        # Called by GA::Cmd::AddWord->do or DeleteWord->do
        # Updates the hash $self->combinedAdjHash after one of the main adjective hashes is modified
        #   (this method is hopefully quicker than calling $self->createCombHashes every time a
        #   single key-value pair is changed)
        #
        # Expected arguments
        #   $adjType    - Which type of adjective  has been changed ('declinedAdj',
        #                   'adj', 'pseudoAdj')
        #   $addFlag    - TRUE if the key-value pair is to be added to the combined hash; FALSE if
        #                   it is to be removed
        #   $key        - ($addFlag = TRUE) The new key; ($addFlag = FALSE) the key to be removed
        #
        # Optional arguments
        #   $value      - ($addFlag = TRUE) The new value ($addFlag = FALSE) 'undef'
        #
        # Return values
        #   'undef' on improper arguments or if the combined hash isn't modified
        #   1 otherwise

        my ($self, $adjType, $addFlag, $key, $value, $check) = @_;

        # Local variables
        my (
            $newPriority, $oldPriority,
            %priorityHash,
        );

        # Check for improper arguments
        if (! defined $adjType || ! defined $addFlag || ! defined $key || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->updateCombAdjHash', @_);
        }

        # Create a hash of priorities, so we can quickly work out what to do with the new key-value
        #   pair
        %priorityHash = (
            'declinedAdj'   => 0,
            'adj'           => 1,
            'pseudoAdj'     => 2,
        );

        # Check that $$adjType is valid
        if (! exists $priorityHash{$adjType} ) {

            # Treat this as an improper argument
            return $axmud::CLIENT->writeImproper($self->_objClass . '->updateCombAdjHash', @_);
        }

        # If the key-value pair is to be added to the combined hash...
        if ($addFlag) {

            # If it doesn't already exist in the hash, simply add it
            if (! $self->ivExists('combAdjHash', $key)) {

                $self->ivAdd('combAdjHash', $key, $value);
                return 1;

            # Otherwise work out which key-value pair has priority
            } else {

                $newPriority = $priorityHash{$value};
                $oldPriority = $priorityHash{$self->ivShow('combAdjHash', $key)};
                if ($oldPriority < $newPriority) {

                    # New key-value pair takes precedence
                    $self->ivAdd('combAdjHash', $key, $value);
                    return 1;

                } else {

                    # Old key-value pair takes precedence; don't change the combined hash
                    return undef;
                }
            }

        # If the key-value pair is to be removed from the combined hash, need to check whether an
        #   adjective from a higher-priority hash should replace it
        #
        # If the key-value pair isn't in the combined hash, no changes to make
        } elsif (! $self->ivExists('combAdjHash', $key)) {

            return undef;

        } else {

            # Remember the priority of the dictionary hash which contains the key-value pair to be
            #   deleted
            $value = $self->ivShow('combAdjHash', $key);
            $newPriority = $priorityHash{$value};

            # Delete the key
            $self->ivDelete('combAdjHash', $key);

            # Check the lower-priority dictionary hashes to see if any of them use the same key
            # Reinstate the first key-value pair found
            if ($newPriority == 2) {       # Axmud dictionaries use 3 adjective hashes

                # No dictionary hashes with lower priority to check
                return 1;

            } else {

                for (my $count = 1; $count <= 2; $count++) {

                    my $hashName = $adjType . 'Hash';
                    if ($newPriority <= $count && $self->ivExists($hashName, $key)) {

                        # The same key was found in this dictionary hash. Reinstate it into the
                        #   combined hash
                        $value = $self->ivShow($hashName, $key);
                        $self->ivAdd('combAdjHash', $key, $value);

                        return 1;
                    }
                }

                # None of the lower-priority dictionary hashes use the same key
                return undef;
            }
        }
    }

    sub updateOppDirHash {

        # Can be called by anything (for example, called by GA::WizWin::Locator->saveChanges)
        # When $self->primaryDirHash and/or $self->primaryAbbrevHash are modified, this function can
        #   be called to update the contents of $self->primaryOppHash and ->primaryOppAbbrevHash
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $check) = @_;

        # Local variables
        my (%dirHash, %abbrevHash, %oppHash, %oppAbbrevHash);

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->updateOppDirHash', @_);
        }

        # Import IVs that we won't change (for simplicity)
        %dirHash = $self->primaryDirHash;
        %abbrevHash = $self->primaryAbbrevHash;

        # Use them to update these IVs
        foreach my $key ($axmud::CLIENT->constPrimaryDirList) {

            $oppHash{$key} = $dirHash{$axmud::CLIENT->ivShow('constOppDirHash', $key)};
            $oppAbbrevHash{$key} = $abbrevHash{$axmud::CLIENT->ivShow('constOppDirHash', $key)};
        }

        $self->ivPoke('primaryOppHash', %oppHash);
        $self->ivPoke('primaryOppAbbrevHash', %oppAbbrevHash);

        $self->createCombDirHash();

        return 1;
    }

    sub convertToPlural {

        # Called by anything
        # Converts any singular noun to its plural form, as best as it can
        #
        # Expected arguments
        #   $word       - The word to convert
        #
        # Return values
        #   The plural form, if a plural form can be found
        #   Otherwise returns $word unaltered (even on improper arguments)

        my ($self, $word, $check) = @_;

        # Local variables
        my @endingList;

        # Check for improper arguments
        if (! defined $word || defined $check) {

            $axmud::CLIENT->writeImproper($self->_objClass . '->convertToPlural', @_);
            return $word;
        }

        # If it's a word with a known plural form, use the plural form
        if ($self->ivExists('pluralNounHash', $word)) {

            return $self->ivShow('pluralNounHash', $word);
        }

        # Import the singular ending list, and sort them in descending order of size, so that (for
        #   example) 'benches' is tested for the plural ending -es before it is tested for the
        #   plural ending -s
        @endingList = sort {length $b <=> length $a} ($self->ivKeys('reversePluralEndingHash'));

        OUTER: foreach my $singularEnding (@endingList) {

            my $pluralEnding;

            # An empty string is the default ending. Instead of doing a substitution, we simply add
            #   the plural ending
            if (! $singularEnding) {

                return $word . $self->ivShow('reversePluralEndingHash', $singularEnding);
            }

            # If the ending exists in this word...
            if ($word =~ m/$singularEnding/) {

                # ...convert the word to its plural form
                $pluralEnding = $self->ivShow('reversePluralEndingHash', $singularEnding);
                $word =~ s/$singularEnding/$pluralEnding/;

                return $word;
            }
        }

        # Failsafe - return the word unaltered
        return $word;
    }

    sub convertToSingular {

        # Called by anything
        # Converts any plural noun to its singular form, as best as it can
        #
        # Expected arguments
        #   $word       - The word to convert
        #
        # Return values
        #   The singular form, if a singular form can be found
        #   Otherwise returns $word unaltered (even on improper arguments)

        my ($self, $word, $check) = @_;

        # Local variables
        my @endingList;

        # Check for improper arguments
        if (! defined $word || defined $check) {

            $axmud::CLIENT->writeImproper($self->_objClass . '->convertToSingular', @_);
            return $word;
        }

        # If it's a known plural noun, convert to the corresponding singular form
        if ($self->ivExists('reversePluralNounHash', $word)) {

            return $self->ivShow('reversePluralNounHash', $word);
        }

        # Import the singular ending list, and sort them in descending order of size, so that (for
        #   example) 'benches' is tested for the plural ending -es before it is tested for the
        #   plural ending -s
        @endingList = sort {length $b <=> length $a} ($self->ivKeys('pluralEndingHash'));

        OUTER: foreach my $pluralEnding (@endingList) {

            my $singularEnding;

            # Ignore any empty strings
            if (! $pluralEnding) {

                next OUTER;
            }

            # If the ending exists in this word...
            if ($word =~ m/$pluralEnding/) {

                # ...convert the word to its singular form
                $singularEnding = $self->ivShow('pluralEndingHash', $pluralEnding);
                $word =~ s/$pluralEnding/$singularEnding/;

                return $word;
            }
        }

        # Otherwise, assume the specified $word wasn't a plural form, and simply
        #   return it
        return $word;
    }

    sub convertToDeclined {

        # Called by anything
        # Converts any undeclined adjective to its declined form, as best as it can
        #
        # Expected arguments
        #   $adj        - The adjective to convert
        #
        # Return values
        #   The declined form, if a declined form can be found
        #   Otherwise returns $adj unaltered (even on improper arguments)

        my ($self, $adj, $check) = @_;

        # Local variables
        my @endingList;

        # Check for improper arguments
        if (! defined $adj || defined $check) {

            $axmud::CLIENT->writeImproper($self->_objClass . '->convertToDeclined', @_);
            return $adj;
        }

        # If it's a word with a known declined form, use the declined form
        if ($self->ivExists('declinedAdjHash', $adj)) {

            return $self->ivShow('declinedAdjHash', $adj);
        }

        # Import the adjective ending list, and sort them in descending order of size, so that (for
        #   example) 'grandes' is tested for the declined ending -es before it is tested for the
        #   undeclined ending -s
        @endingList = sort {length $b <=> length $a} ($self->ivKeys('reverseAdjEndingHash'));

        OUTER: foreach my $undeclinedEnding (@endingList) {

            my $declinedEnding;

            # An empty string is the default ending. Instead of doing a substitution, we simply add
            #   the declined ending
            if (! $undeclinedEnding) {

                return $adj . $self->ivShow('reverseAdjEndingHash', $undeclinedEnding);
            }

            # If the ending exists in this word...
            if ($adj =~ m/$undeclinedEnding/) {

                # ...convert the word to its declined form
                $declinedEnding = $self->ivShow('reverseAdjEndingHash', $undeclinedEnding);
                $adj =~ s/$undeclinedEnding/$declinedEnding/;

                return $adj;
            }
        }

        # Failsafe - return the word unaltered
        return $adj;
    }

    sub convertToUndeclined {

        # Called by anything
        # Converts any declined adjective to its undeclined form, as best as it can
        #
        # Expected arguments
        #   $adj        - The adjective to convert
        #
        # Return values
        #   The undeclined form, if an undeclined form can be found
        #   Otherwise returns $adj unaltered (even on improper arguments)

        my ($self, $adj, $check) = @_;

        # Local variables
        my @endingList;

        # Check for improper arguments
        if (! defined $adj || defined $check) {

            $axmud::CLIENT->writeImproper($self->_objClass . '->convertToUndeclined', @_);
            return $adj;
        }

        # If it's a word with a known undeclined form, use the undeclined form
        if ($self->ivExists('reverseDeclinedAdjHash', $adj)) {

            return $self->ivShow('reverseDeclinedAdjHash', $adj);
        }

        # Import the adjective ending list, and sort them in descending order of size, so that (for
        #   example) 'grandes' is tested for the declined ending -es before it is tested for the
        #   undeclined ending -s
        @endingList = sort {length $b <=> length $a} ($self->ivKeys('adjEndingHash'));

        OUTER: foreach my $declinedEnding (@endingList) {

            my $undeclinedEnding;

            # Ignore any empty strings
            if (! $declinedEnding) {

                next OUTER;
            }

            # If the ending exists in this word...
            if ($adj =~ m/$declinedEnding/) {

                # ...reduce the word to its undeclined form
                $undeclinedEnding = $self->ivShow('adjEndingHash', $declinedEnding);
                $adj =~ s/$declinedEnding/$undeclinedEnding/;

                return $adj;
            }
        }

        # Otherwise, assume the specified $adj wasn't a declined form, and simply return it
        return $adj;
    }

    # Modify directions

    sub modifyPrimaryDir {

        # Called by GA::Cmd::ModifyPrimary->do or any other code
        # Modifies a primary direction and its abbreviation, updating others hashes as required
        #
        # NB So that a calling function can replace all directions in one go, it's the calling
        #   function's responsibility to check that a custom direction doesn't already exist as a
        #   custom primary, secondary or relative direction, before calling this function
        #
        # Expected arguments
        #   $standardDir    - The standard primary direction, a key in $self->primaryDirHash
        #   $customDir      - A custom primary direction, the corresponding value in
        #                       $self->primaryDirHash
        #
        # Optional arguments
        #   $customAbbrev   - The abbreviated custom primary direction, the corresponding value in
        #                       $self->primaryAbbrevHash. If 'undef' or an empty string, the custom
        #                       direction and its abbreviation are the same
        #   $noUpdateFlag   - If TRUE, the calling function expects to call this function several
        #                       times, in which case $self->updateOppDirHash is not called (it's up
        #                       to the calling function to do it, when ready). If FALSE (or
        #                       'undef'), other hashes are updated as required
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $standardDir, $customDir, $customAbbrev, $noUpdateFlag, $check) = @_;

        # Check for improper arguments
        if (! defined $standardDir || ! defined $customDir || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->modifyPrimaryDir', @_);
        }

        if (! defined $customAbbrev || $customAbbrev eq '') {

            $customAbbrev = $customDir;
        }

        $self->ivAdd('primaryDirHash', $standardDir, $customDir);
        $self->ivAdd('primaryAbbrevHash', $standardDir, $customAbbrev);

        if (! $noUpdateFlag) {

            $self->updateOppDirHash();
        }

        # Operation complete
        return 1;
    }

    sub addSecondaryDir {

        # Called by GA::Cmd::AddSecondary->do or any other code
        # Adds a secondary direction and its abbreviation (if any), updating others hashes as
        #   required
        #
        # NB So that a calling function can replace all directions in one go, it's the calling
        #   function's responsibility to check that a custom direction doesn't already exist as a
        #   custom primary, secondary or relative direction direction, before calling this function
        # NB Note that $self->secondaryDirList exists, but no $self->primaryDirList exists; also
        #   abbreviated secondary directions are set to 'undef' by default; so this function behaves
        #   slightly differently to $self->modifyPrimaryDir
        #
        # Expected arguments
        #   $customDir      - A custom secondary direction, stored as both a key and a value in
        #                       $self->secondaryDirHash
        #
        # Optional arguments
        #   $customAbbrev   - The abbreviated custom secondary direction. If 'undef' or an empty
        #                       string, the abbreviation is stored as 'undef'
        #   $noUpdateFlag   - If TRUE, the calling function expects to call this function several
        #                       times, in which case $self->updateOppDirHash is not called (it's up
        #                       to the calling function to do it, when ready). If FALSE (or
        #                       'undef'), other hashes are updated as required
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $customDir, $customAbbrev, $noUpdateFlag, $check) = @_;

        # Check for improper arguments
        if (! defined $customDir || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->addSecondaryDir', @_);
        }

        if (defined $customAbbrev && $customAbbrev eq '') {

            $customAbbrev = undef;
        }

        $self->ivPush('secondaryDirList', $customDir);
        $self->ivAdd('secondaryDirHash', $customDir, $customDir);
        $self->ivAdd('secondaryAbbrevHash', $customDir, $customAbbrev);
        $self->ivAdd('secondaryOppHash', $customDir, '');
        $self->ivAdd('secondaryOppAbbrevHash', $customDir, '');
        $self->ivAdd('secondaryAutoHash', $customDir, undef);

        if (! $noUpdateFlag) {

            $self->updateOppDirHash();
        }

        # Operation complete
        return 1;
    }

    sub modifySecondaryDir {

        # Called by GA::Cmd::ModifySecondary->do or any other code
        # Sets the opposite direction of an existing custom secondary direction, updating others
        #   hashes as required
        #
        # NB So that a calling function can replace all directions in one go, it's the calling
        #   function's responsibility to check that a custom direction doesn't already exist as a
        #   custom primary, secondary or relative direction, before calling this function
        #
        # Expected arguments
        #   $customDir      - A custom secondary direction, stored as both a key and a value in
        #                       $self->secondaryDirList
        #
        # Optional arguments
        #   $oppDir         - The opposite custom secondary direction. If 'undef' or an empty
        #                       string, $customDir has no opposite direction
        #
        # Optional arguments
        #   $noUpdateFlag   - If TRUE, the calling function expects to call this function several
        #                       times, in which case $self->updateOppDirHash is not called (it's up
        #                       to the calling function to do it, when ready). If FALSE (or
        #                       'undef'), other hashes are updated as required
        #
        # Return values
        #   'undef' on improper arguments, if $customDir isn't a custom secondary direction, of if
        #       $customAbbrev is specified and it, too, is not a custom secondary direction
        #   1 otherwise

        my ($self, $customDir, $oppDir, $noUpdateFlag, $check) = @_;

        # Check for improper arguments
        if (! defined $customDir || ! defined $oppDir || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->modifySecondaryDir', @_);
        }

        if (! defined $oppDir) {

            $oppDir = '';
        }

        if (
            ! $self->ivExists('secondaryDirHash', $customDir)
            || ($oppDir ne '' && ! $self->ivExists('secondaryDirHash', $oppDir))
        ) {
            return undef;
        }

        $self->ivAdd('secondaryOppHash', $customDir, $oppDir);
        $self->ivAdd(
            'secondaryOppAbbrevHash',
            $customDir,
            $self->ivShow('secondaryAbbrevHash', $oppDir),
        );

        if (! $noUpdateFlag) {

            $self->updateOppDirHash();
        }

        # Operation complete
        return 1;
    }

    sub deleteSecondaryDir {

        # Called by GA::Cmd::DeleteSecondary->do or any other code
        # Deletes a secondary direction and its abbreviation (if any), updating others hashes as
        #   required
        #
        # Expected arguments
        #   $customDir      - A custom secondary direction, stored as both a key and a value in
        #                       $self->secondaryDirHash
        #
        # Optional arguments
        #   $noUpdateFlag   - If TRUE, the calling function expects to call this function several
        #                       times, in which case $self->updateOppDirHash is not called (it's up
        #                       to the calling function to do it, when ready). If FALSE (or
        #                       'undef'), other hashes are updated as required
        #
        # Return values
        #   'undef' on improper arguments or if the specified custom secondary direction doesn't
        #       exist
        #   1 otherwise

        my ($self, $customDir, $noUpdateFlag, $check) = @_;

        # Check for improper arguments
        if (! defined $customDir || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->deleteSecondaryDir', @_);
        }

        if (! $self->ivExists('secondaryDirHash', $customDir)) {

            return undef;
        }

        $self->ivSplice('secondaryDirList', $self->ivMatch('secondaryDirList', $customDir), 1);
        $self->ivDelete('secondaryDirHash', $customDir);
        $self->ivDelete('secondaryAbbrevHash', $customDir);
        $self->ivDelete('secondaryAutoHash', $customDir);

        if (! $noUpdateFlag) {

            $self->updateOppDirHash();
        }

        # Operation complete
        return 1;
    }

    sub addRelativeDir {

        # Called by GA::Cmd::AddRelative->do or any other code
        # Adds a relative direction and its abbreviation (if any), updating others hashes as
        #   required
        #
        # NB So that a calling function can replace all directions in one go, it's the calling
        #   function's responsibility to check that a relative direction doesn't already exist as a
        #   custom primary, secondary or relative direction, before calling this function
        #
        # Expected arguments
        #   $index          - An integer in the range 0-7, matching the keys in
        #                       $self->relativeDirHash. 0 represents 'forward', 2 represents 'right'
        #                       and so on
        #   $relativeDir    - A relative direction, stored as both a key and a value in
        #                       $self->relativeDirHash
        #
        # Optional arguments
        #   $relativeAbbrev - The abbreviated relative direction. If 'undef' or an empty
        #                       string, no key-value pair is added to $self->relativeAbbrevHash
        #   $noUpdateFlag   - If TRUE, the calling function expects to call this function several
        #                       times, in which case $self->updateOppDirHash is not called (it's up
        #                       to the calling function to do it, when ready). If FALSE (or
        #                       'undef'), other hashes are updated as required
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $index, $relativeDir, $relativeAbbrev, $noUpdateFlag, $check) = @_;

        # Check for improper arguments
        if (
            ! defined $index
            || ! $axmud::CLIENT->intCheck($index, 0, 7)
            || ! defined $relativeDir || defined $check
        ) {
            return $axmud::CLIENT->writeImproper($self->_objClass . '->addRelativeDir', @_);
        }

        $self->ivAdd('relativeDirHash', $index, $relativeDir);
        if (defined $relativeAbbrev && $relativeAbbrev ne '') {

            $self->ivAdd('relativeAbbrevHash', $index, $relativeAbbrev);
        }

        if (! $noUpdateFlag) {

            $self->updateOppDirHash();
        }

        # Operation complete
        return 1;
    }

    sub deleteRelativeDir {

        # Called by GA::Cmd::DeleteRelative->do or any other code
        # Deletes a relative direction and its abbreviation (if any), updating others hashes as
        #   required
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Optional arguments (one or both can be specified)
        #   $index          - An integer in the range 0-7, matching a key in $self->relativeDirHash
        #   $relativeDir    - A relative direction, matching a value in $self->relativeDirHash
        #   $noUpdateFlag   - If TRUE, the calling function expects to call this function several
        #                       times, in which case $self->updateOppDirHash is not called (it's up
        #                       to the calling function to do it, when ready). If FALSE (or
        #                       'undef'), other hashes are updated as required
        #
        # Return values
        #   'undef' on improper arguments, if both $index and $relativeDir are undefined, or if the
        #       specified index or relative direction doesn't exist
        #   1 otherwise

        my ($self, $index, $relativeDir, $noUpdateFlag, $check) = @_;

        # Local variables
        my %revHash;

        # Check for improper arguments
        if (defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->deleteRelativeDir', @_);
        }

        # If neither $index nor $relativeDir are specified, then there's nothing to delete
        if (
            ! $axmud::CLIENT->intCheck($index, 0, 7)
            && (! defined $relativeDir || $relativeDir eq '')
        ) {
            return undef;
        }

        if (! defined $index) {

            %revHash = reverse $self->relativeDirHash;
            if (! exists $revHash{$relativeDir}) {

                return undef;

            } else {

                $index = $revHash{$relativeDir};
            }
        }

        $self->ivDelete('relativeDirHash', $index);
        $self->ivDelete('relativeAbbrevHash', $index);

        if (! $noUpdateFlag) {

            $self->updateOppDirHash();
        }

        # Operation complete
        return 1;
    }

    # Phrasebooks

    sub uploadPhrasebook {

        # A phrasebook object (GA::Obj::Phrasebook) stores basic vocabulary for a language -
        #   primary directions (and their abbreviations), articles, conjunctions and number words.
        #   The phrasebook object also stores equivalents to this object's ->language and ->nounPosn
        #   IVs
        # Phrasebooks are loaded from text files in /items/phrasebooks, and can't be modified by the
        #   user (although the text files could be edited, of course)
        # This function can be called by anything to upload the contents of the phrasebook to this
        #   dictionary, replacing existing primary directions, articles, etc (but not modifying
        #   secondary directions, nouns, time units, etc)
        #
        # Expected arguments
        #   $pbObj  - The Games::Axmud::Obj::Phrasebook object whose contents is to be uploaded
        #
        # Return values
        #   'undef' on improper arguments
        #   1 otherwise

        my ($self, $pbObj, $check) = @_;

        # Local variables
        my (
            @dirList, @abbrevList, @numberList,
            %dirHash, %abbrevHash,
        );

        # Check for improper arguments
        if (! defined $pbObj || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->uploadPhrasebook', @_);
        }

        # (We'll assume the user hasn't been messing with the phrasebook text files, and that
        #   thefore none of these values need to be checked)
        $self->ivPoke('language', $pbObj->targetName);
        $self->ivPoke('nounPosn', $pbObj->nounPosn);

        @dirList = $pbObj->primaryDirList;
        @abbrevList = $pbObj->primaryAbbrevDirList;

        foreach my $standard ($axmud::CLIENT->constPrimaryDirList) {

            $dirHash{$standard} = shift @dirList;
            $abbrevHash{$standard} = shift @abbrevList;
        }

        $self->ivPoke('primaryDirHash', %dirHash);
        $self->ivPoke('primaryAbbrevHash', %abbrevHash);
        $self->updateOppDirHash();

        $self->ivPoke('definiteList', $pbObj->definiteList);
        $self->ivPoke('indefiniteList', $pbObj->indefiniteList);
        $self->ivPoke('andList', $pbObj->andList);
        $self->ivPoke('orList', $pbObj->orList);

        @numberList = $pbObj->numberList;
        for (my $count = 1; $count <= 10; $count++) {

            $self->ivAdd('numberHash', shift @numberList, $count);
        }

        $self->createCombDirHash();

        # Operation complete
        return 1;
    }

    # Misc

    sub checkPrimaryDir {

        # Can be called by anything
        # Checks whether a specified direction is a primary direction. If so, returns the
        #   unabbreviated form of the (custom) primary direction
        #
        # Expected arguments
        #   $dir        - The direction to check (full or abbreviated form)
        #
        # Return values
        #   'undef' on improper arguments or if $dir isn't a primary direction
        #   Otherwise returns the unabbreviated primary direction

        my ($self, $dir, $check) = @_;

        # Local variables
        my ($type, $standard);

        # Check for improper arguments
        if (! defined $dir || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->checkPrimaryDir', @_);
        }

        # Perform the check
        $type = $self->ivShow('combDirHash', $dir);
        if (defined $type) {

            if ($type eq 'primaryDir') {

                # $dir is already a primary direction
                return $dir;

            } elsif ($type eq 'primaryAbbrev') {

                # Get the standard direction
                $standard = $self->ivShow('combRevDirHash', $dir);
                return $self->ivShow('primaryDirHash', $standard);
            }
        }

        # Not a (custom) primary direction
        return undef;
    }

    sub checkSecondaryDir {

        # Can be called by anything
        # Checks whether a specified direction is a secondary direction. If so, returns the
        #   unabbreviated form of the (recognised) secondary direction
        #
        # Expected arguments
        #   $dir        - The direction to check (full or abbreviated form)
        #
        # Return values
        #   'undef' on improper arguments or if $dir isn't a secondary direction
        #   Otherwise returns the unabbreviated secondary direction

        my ($self, $dir, $check) = @_;

        # Local variables
        my ($type, $recognised);

        # Check for improper arguments
        if (! defined $dir || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->checkSecondaryDir', @_);
        }

        # Perform the check
        $type = $self->ivShow('combDirHash', $dir);
        if (defined $type) {

            if ($type eq 'secondaryDir') {

                # $dir is already a secondary direction
                return $dir;

            } elsif ($type eq 'secondaryAbbrev') {

                # Get the recognised direction
                $recognised = $self->ivShow('combRevDirHash', $dir);
                return $self->ivShow('secondaryDirHash', $recognised);
            }
        }

        # Not a (recognised) secondary direction
        return undef;
    }

    sub checkRelativeDir {

        # Can be called by anything
        # Checks whether a specified direction is a relative direction. If so, returns the
        #   unabbreviated form of the (recognised) relative direction
        #
        # Expected arguments
        #   $dir        - The direction to check (full or abbreviated form)
        #
        # Return values
        #   'undef' on improper arguments or if $dir isn't a relative direction
        #   Otherwise returns the unabbreviated relative direction

        my ($self, $dir, $check) = @_;

        # Local variables
        my (
            $type, $index,
            %revHash,
        );

        # Check for improper arguments
        if (! defined $dir || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->checkRelativeDir', @_);
        }

        # Perform the check
        $type = $self->ivShow('combDirHash', $dir);
        if (defined $type) {

            if ($type eq 'relativeDir') {

                # $dir is already a relative direction
                return $dir;

            } elsif ($type eq 'relativeAbbrev') {

                # $self->combRevDirHash doesn't contain relative directions
                %revHash = reverse $self->relativeAbbrevHash;
                if (! exists $revHash{$dir}) {

                    return undef;

                } else {

                    $index = $revHash{$dir};
                    return $self->ivShow('relativeDirHash', $index);
                }
            }
        }

        # Not a (recognised) relative direction
        return undef;
    }

    sub checkOppDir {

        # Can be called by anything
        #
        # $self->combOppDirHash is in the form
        #   ->combOppDirHash{custom_direction} = custom_opposite_direction
        # ...where 'custom_opposite_direction' is a string containing one or more directions, e.g.
        #   'out' or 'out door exit'
        #
        # This function takes two custom directions as arguments. If the first one is a key in
        #   $self->combOppDirHash, and if the second one is one of the directions listed in the
        #   key's corresponding value, this function returns TRUE; otherwise it returns 'undef'
        #
        # Expected arguments
        #   $key        - A custom direction
        #   $dir        - Another custom direction
        #
        # Return values
        #   'undef' on improper arguments
        #   Otherwise returns TRUE or 'undef', as described above

        my ($self, $key, $dir, $check) = @_;

        # Local variables
        my (
            $string,
            @list,
        );

        # Check for improper arguments
        if (! defined $key || ! defined $dir || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->checkOppDir', @_);
        }

        # Perform the check
        $string = $self->ivShow('combOppDirHash', $key);
        if (! defined $string) {

            return undef;
        }

        # Split $string into a list of words (we presume that all secondary directions are single
        #   words)
        @list = split(m/\s+/, $string);
        foreach my $item (@list) {

            if ($item eq $dir) {

                return TRUE;
            }
        }

        # $key and $dir are not opposite (custom) directions
        return undef;
    }

    sub convertStandardDir {

        # Can be called by anything, but often used for creating exit objects
        # Checks whether a specified direction is a primary direction. If so, returns the
        #   equivalent standard direction (e.g. converts 'nord', 'n' to 'north')
        #
        # Expected arguments
        #   $dir        - The direction to check (full or abbreviated form)
        #
        # Return values
        #   'undef' on improper arguments or if $dir isn't a primary direction
        #   Otherwise returns the standard primary direction

        my ($self, $dir, $check) = @_;

        # Local variables
        my $type;

        # Check for improper arguments
        if (! defined $dir || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->convertStandardDir', @_);
        }

        # Perform the check
        $type = $self->ivShow('combDirHash', $dir);
        if (defined $type && ($type eq 'primaryDir' || $type eq 'primaryAbbrev')) {

            # Return the standard direction
            return $self->ivShow('combRevDirHash', $dir);

        } else {

            # $dir is not a (custom) primary direction
            return undef;
        }
    }

    sub convertRelativeDir {

        # Can be called by anything
        # Checks whether a specified direction is a relative direction. If so, returns an integer
        #   in the range 0-7 matching the keys in $self->relativeDirHash. 0 represents 'forward', 2
        #   represents 'right' and so on
        #
        # Expected arguments
        #   $dir        - The direction to check (full or abbreviated form)
        #
        # Return values
        #   'undef' on improper arguments or if $dir isn't a relative direction
        #   Otherwise returns the equivalent integer

        my ($self, $dir, $check) = @_;

        # Local variables
        my (
            $type,
            %revHash,
        );

        # Check for improper arguments
        if (! defined $dir || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->convertRelativeDir', @_);
        }

        # Perform the check
        $type = $self->ivShow('combDirHash', $dir);
        if (defined $type) {

            # (For other $types, %revHash remains empty, so the return value will be 'undef'
            if ($type eq 'relativeDir') {
                %revHash = reverse $self->relativeDirHash;
            } elsif ($type eq 'relativeAbbrev') {
                %revHash = reverse $self->relativeAbbrevHash;
            }

            return $revHash{$dir};

        } else {

            # Not a relative direction
            return undef;
        }
    }

    sub rotateRelativeDir {

        # Can be called by anything, usually after a call to $self->convertRelativeDir
        # Given one of the relative direction slots (an integer in the range 0-7 matching the keys
        #   in $self->relativeDirHash. 0 represents 'forward', 2 represents 'right' and so on) and
        #   the direction the character is currently facing, returns the equivalent standard primary
        #   direction. For example:
        #
        #   Character is facing     Specified slot      Returns
        #   west                    0                   west
        #   west                    1                   northwest
        #   west                    2                   north
        #
        #   southwest               0                   southwest
        #   southwest               4                   northeast
        #   southwest               7                   south
        #
        # Expected arguments
        #   $slot       - An integer in the range 0-7
        #
        # Optional arguments
        #   $facingDir  - The direction the character is currently facing (must be one of the
        #                   following standard primary directions: north/northeast/east/southeast/
        #                   south/southwest/west/northwest). If it's a different direction, this
        #                   function returns 'undef'; but if $facingDir is not defined at all,
        #                   we'll assume the character is facing north
        #
        # Return values
        #   'undef' on improper arguments, if $slot is invalid or if $facingDir is specified and
        #       invalid
        #   Otherwise returns the equivalent standard primary direction

        my ($self, $slot, $facingDir, $check) = @_;

        # Local variables
        my $otherSlot;

        # Check for improper arguments
        if (! defined $slot || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->rotateRelativeDir', @_);
        }

        # Check any arguments are valid
        if (
            ! $axmud::CLIENT->intCheck($slot, 0, 7)
            || (
                defined $facingDir
                && (
                    ! $axmud::CLIENT->ivExists('constShortPrimaryDirHash', $facingDir)
                    || $facingDir eq 'up'
                    || $facingDir eq 'down'
                )
            )
        ) {
            return undef;
        }

        # If $facingDir is not defined, assume the character is facing north
        if (! defined $facingDir) {

            $facingDir = 'north';
        }

        # Find the slot number representing $facingDir. By good fortune, the first eight items in
        #   GA::Client->constShortPrimaryDirList are in the correct order
        $otherSlot = $axmud::CLIENT->ivFind('constShortPrimaryDirList', $facingDir);

        # Rotate $slot to take into account the direction the character is facing
        $slot += $otherSlot;
        if ($slot > 7) {

            $slot -= 8;
        }

        return $axmud::CLIENT->ivIndex('constShortPrimaryDirList', $slot);
    }

    sub fetchRelativeDir {

        # Can be called by anything
        # Fetch the direction, relative to the direction in which the character is facing, of a
        #   primary direction. For example:
        #
        #   Character is facing     Specified direction Returns
        #   east                    east                forward
        #   east                    south               right
        #   east                    west                backward
        #   east                    north               left
        #
        # Expected arguments
        #   $dir        - The specified direction (must be one of the following standard primary
        #                   directions: north/northeast/east/southeast/south/southwest/west/
        #                   northwest)
        #
        # Optional arguments
        #   $facingDir  - The direction the character is currently facing (must be one of the
        #                   following standard primary directions: north/northeast/east/southeast/
        #                   south/southwest/west/northwest)
        #               - GA::Obj::Map->facingDir can be 'undef', so this function won't complain of
        #                   improper arguments if $facingDir is 'undef', but no relative direction
        #                   will be returned
        #
        # Return values
        #   'undef' on improper arguments, if either argument is an invalid direction, if
        #       $facingDir is 'undef' or if the corresponding relative direction has not been
        #       defined
        #   Otherwise returns the equivalent relative direction

        my ($self, $dir, $facingDir, $check) = @_;

        # Local variables
        my ($slot, $otherSlot);

        # Check for improper arguments
        if (! defined $dir || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->fetchRelativeDir', @_);
        }

        # Unlike other dictionary object functions, here we don't assume the character is facing
        #   'north' if $facingDir is not defined
        if (! $facingDir) {

            return undef;
        }

        # Check the directions are valid
        $slot = $axmud::CLIENT->ivFind('constShortPrimaryDirList', $dir);
        if (! $axmud::CLIENT->intCheck($slot, 0, 7)) {

            return undef;
        }

        $otherSlot = $axmud::CLIENT->ivFind('constShortPrimaryDirList', $facingDir);
        if (! $axmud::CLIENT->intCheck($otherSlot, 0, 7)) {

            return undef;
        }

        # Rotate $slot to take into account the direction the character is facing
        $slot += $otherSlot;
        if ($slot > 7) {

            $slot -= 8;
        }

        # Return the corresponding relative direction (or 'undef' if it's not defined)
        return $self->ivShow('relativeDirHash', $slot);
    }

    sub sortExits {

        # Can be called by anything (no longer called by GA::Task::Locator->processExits)
        # Sorts a list of exit strings (e.g. 'south', 'north', 'up) into a standard order (provided
        #   by the current dictionary), and substitutes any abbreviated exits for the unabbreviated
        #   forms (e.g. converts 'n' to 'north')
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Optional arguments
        #   @exitList   - List of exits (may be empty)
        #
        # Return values
        #   An empty list on improper arguments
        #   Otherwise, the sorted list

        my ($self, @exitList) = @_;

        # Local variables
        my (
            @primaryDirList, @secondaryDirList, @sortedList, @otherList,
            %exitHash, %primaryDirHash, %primaryAbbrevHash, %secondaryDirHash, %secondaryAbbrevHash,
            %relativeDirHash, %relativeAbbrevHash,
        );

        # (No improper arguments to check)

        # Copy the exits in @exitList into a hash, for quick lookup; but preserve duplicates. Hash
        #   in the form
        #   $exitHash{exit} = number_of_appearances
        foreach my $exit (@exitList) {

            if (! exists $exitHash{$exit}) {

                $exitHash{$exit} = 1;

            } else {

                $exitHash{$exit} = $exitHash{$exit} + 1;
            }
        }

        # Import IVs
        @primaryDirList = $axmud::CLIENT->constPrimaryDirList;
        %primaryDirHash = $self->primaryDirHash;
        %primaryAbbrevHash = $self->primaryAbbrevHash;
        @secondaryDirList = $self->secondaryDirList;
        %secondaryDirHash = $self->secondaryDirHash;
        %secondaryAbbrevHash = $self->secondaryAbbrevHash;
        %relativeDirHash = $self->relativeDirHash;
        %relativeAbbrevHash = $self->relativeAbbrevHash;

        # @sortedList is the list of exits, in the default order. Add primary directions
        foreach my $standard (@primaryDirList) {

            my ($match, $number);

            if (exists $exitHash{$primaryDirHash{$standard}}) {

                $match = $primaryDirHash{$standard};
                $number = $exitHash{$match};
                delete $exitHash{$match};

            } elsif (exists $exitHash{$primaryAbbrevHash{$standard}}) {

                $match = $primaryAbbrevHash{$standard};
                $number = $exitHash{$match};
                delete $exitHash{$match};
            }

            if ($match) {

                for (my $count = 0; $count < $number; $count++) {

                    push (@sortedList, $match);
                }
            }
        }

        # Add secondary directions
        foreach my $recognised (@secondaryDirList) {

            my ($match, $number);

            if (
                defined $secondaryDirHash{$recognised}
                && exists $exitHash{$secondaryDirHash{$recognised}}
            ) {
                $match = $secondaryDirHash{$recognised};
                $number = $exitHash{$match};
                delete $exitHash{$match};

            } elsif (
                defined $secondaryAbbrevHash{$recognised}
                && exists $exitHash{$secondaryAbbrevHash{$recognised}}
            ) {
                $match = $secondaryAbbrevHash{$recognised};
                $number = $exitHash{$match};
                delete $exitHash{$match};
            }

            if ($match) {

                for (my $count = 0; $count < $number; $count++) {

                    push (@sortedList, $match);
                }
            }
        }

        # Add relative directions
        for (my $count = 0; $count < 8; $count++) {

            my ($match, $number);

            if (
                exists $relativeDirHash{$count}
                && exists $exitHash{$relativeDirHash{$count}}
            ) {
                $match = $relativeDirHash{$count};
                $number = $exitHash{$match};
                delete $exitHash{$match};

            } elsif (
                exists $relativeAbbrevHash{$count}
                && exists $exitHash{$relativeAbbrevHash{$count}}
            ) {
                $match = $relativeAbbrevHash{$count};
                $number = $exitHash{$match};
                delete $exitHash{$match};
            }

            if ($match) {

                for (my $count = 0; $count < $number; $count++) {

                    push (@sortedList, $match);
                }
            }
        }

        # Now, any exits in @exitList which aren't primary or secondary directions will still be
        #   in %exitHash. Add them to @otherList in their original order
        foreach my $exit (@exitList) {

            if (exists $exitHash{$exit}) {

                for (my $count = 0; $count < $exitHash{$exit}; $count++) {

                    push (@otherList, $exit);
                }
            }
        }

        # The final list consists of all primary/secondary directions in their default order,
        #   followed by any other directions in alphabetical order
        if (@otherList) {

            push (@sortedList, sort {lc($a) cmp lc($b)} (@otherList));
        }

        # Sort complete
        return @sortedList;
    }

    sub sortExitObjs {

        # Called by GA::Task::Locator->processExits, or by any other code
        # Sorts a list of exit objects (e.g. 'south', 'north', 'up) into a standard order (provided
        #   by the current dictionary), and substitutes any abbreviated exits for the unabbreviated
        #   forms (e.g. converts 'n' to 'north')
        #
        # Expected arguments
        #   (none besides $self)
        #
        # Optional arguments
        #   @objList   - List of exit objects (may be empty)
        #
        # Return values
        #   An empty list on improper arguments
        #   Otherwise, the sorted list

        my ($self, @objList) = @_;

        # Local variables
        my (
            @primaryDirList, @secondaryDirList, @sortedList, @otherList,
            %dirHash, %objHash, %primaryDirHash, %primaryAbbrevHash, %secondaryDirHash,
            %secondaryAbbrevHash, %relativeDirHash, %relativeAbbrevHash,
        );

        # (No improper arguments to check)

        # Copy the exit objects in @objList into a hash, for quick lookup; but preserve duplicates.
        #   Hash in the form
        #   $dirHash{exit_nominal_direction} = number_of_appearances
        foreach my $exitObj (@objList) {

            my $dir = $exitObj->dir;

            if (! exists $dirHash{$dir}) {

                $dirHash{$dir} = 1;

            } else {

                $dirHash{$dir} = $dirHash{$dir} + 1;
            }

            # Create a parallel hash, in the form
            #   $objHash{exit_nominal_direction} = blessed_reference_to_exit_object
            # ...but, in this hash, duplicate nominal directions aren't added
            if (! exists $objHash{$dir}) {

                $objHash{$dir} = $exitObj;
            }
        }

        # Import IVs
        @primaryDirList = $axmud::CLIENT->constPrimaryDirList;
        %primaryDirHash = $self->primaryDirHash;
        %primaryAbbrevHash = $self->primaryAbbrevHash;
        @secondaryDirList = $self->secondaryDirList;
        %secondaryDirHash = $self->secondaryDirHash;
        %secondaryAbbrevHash = $self->secondaryAbbrevHash;
        %relativeDirHash = $self->relativeDirHash;
        %relativeAbbrevHash = $self->relativeAbbrevHash;

        # @sortedList is the list of exit objects, in the default order. Add primary directions
        foreach my $standard (@primaryDirList) {

            my ($match, $matchObj, $number);

            if (exists $dirHash{$primaryDirHash{$standard}}) {

                $match = $primaryDirHash{$standard};
                $matchObj = $objHash{$match};
                $number = $dirHash{$match};

                delete $dirHash{$match};

            } elsif (exists $dirHash{$primaryAbbrevHash{$standard}}) {

                $match = $primaryAbbrevHash{$standard};
                $matchObj = $objHash{$match};
                $number = $dirHash{$match};

                delete $dirHash{$match};
            }

            if ($match) {

                for (my $count = 0; $count < $number; $count++) {

                    push (@sortedList, $matchObj);
                }
            }
        }

        # Add secondary directions
        foreach my $recognised (@secondaryDirList) {

            my ($match, $matchObj, $number);

            if (
                defined $secondaryDirHash{$recognised}
                && exists $dirHash{$secondaryDirHash{$recognised}}
            ) {
                $match = $secondaryDirHash{$recognised};
                $matchObj = $objHash{$match};
                $number = $dirHash{$match};

                delete $dirHash{$match};

            } elsif (
                defined $secondaryAbbrevHash{$recognised}
                && exists $dirHash{$secondaryAbbrevHash{$recognised}}
            ) {
                $match = $secondaryAbbrevHash{$recognised};
                $matchObj = $objHash{$match};
                $number = $dirHash{$match};

                delete $dirHash{$match};
            }

            if ($match) {

                for (my $count = 0; $count < $number; $count++) {

                    push (@sortedList, $matchObj);
                }
            }
        }

        # Add relative directions
        for (my $count = 0; $count < 8; $count++) {

            my ($match, $matchObj, $number);

            if (
                exists $relativeDirHash{$count}
                && exists $dirHash{$relativeDirHash{$count}}
            ) {
                $match = $relativeDirHash{$count};
                $matchObj = $objHash{$match};
                $number = $dirHash{$match};

                delete $dirHash{$match};

            } elsif (
                exists $relativeAbbrevHash{$count}
                && exists $dirHash{$relativeAbbrevHash{$count}}
            ) {
                $match = $relativeAbbrevHash{$count};
                $matchObj = $objHash{$match};
                $number = $dirHash{$match};

                delete $dirHash{$match};
            }

            if ($match) {

                for (my $count = 0; $count < $number; $count++) {

                    push (@sortedList, $matchObj);
                }
            }
        }

        # Now, any exits in @objList which aren't primary or secondary directions will still be
        #   in %dirHash. Add them to @otherList in their original order
        foreach my $exitObj (@objList) {

            my $dir = $exitObj->dir;

            if (exists $dirHash{$dir}) {

                for (my $count = 0; $count < $dirHash{$dir}; $count++) {

                    push (@otherList, $exitObj);
                }
            }
        }

        # The final list consists of all primary/secondary directions in their default order,
        #   followed by any other directions in alphabetical order
        if (@otherList) {

            push (@sortedList, sort {lc($a->dir) cmp lc($b->dir)} (@otherList));
        }

        # Sort complete
        return @sortedList;
    }

    sub abbrevDir {

        # Can be called by anything
        #
        # Given a standard primary direction or a custom primary direction, returns the
        #   corresponding custom abbreviated primary direction
        #       (e.g. converts 'north' or 'nord' to 'n')
        #
        # Given a recognised secondary direction, returns the corresponding abbreviated direction
        #       (e.g. converts 'out' to 'o')
        # If the recognised secondary direction doesn't have an abbreviation (which it doesn't, by
        #   default), returns 'undef')
        #
        # Given a recognised relative direction, returns the corresponding abbreviated direction
        #       (re.g. converts 'forward' to 'fw')
        # If the recognised relative direction doesn't have an abbreviation (which it doesn't, by
        #   default), returns 'undef')
        #
        # Otherwise, returns the direction unmodified
        #
        # Expected arguments
        #   $dir    - The standard, custom primary/secondary or relative direction to abbreviate
        #
        # Return values
        #   'undef' on improper arguments or if $dir is a recognised secondary/relative direction
        #       which has no abbreviation
        #   The abbreviated (or original) direction, otherwise

        my ($self, $dir, $check) = @_;

        # Local variables
        my (
            $type, $standard, $recognised, $index,
            %revHash,
        );

        # Check for improper arguments
        if (! defined $dir || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->abbrevDir', @_);
        }

        # If it's a standard primary direction...
        if ($self->ivExists('primaryAbbrevHash', $dir)) {

            # Return the abbreviated custom direction
            return $self->ivShow('primaryAbbrevHash', $dir);
        }

        $type = $self->ivShow('combDirHash', $dir);
        if (defined $type) {

            # If it's a custom primary direction...
            if ($type eq 'primaryDir') {

                # Find the standard primary direction
                $standard = $self->ivShow('combRevDirHash', $dir);
                # Convert that into the custom abbreviated direction
                return $self->ivShow('primaryAbbrevHash', $standard);

            # If it's a recognised secondary direction...
            } elsif ($type eq 'secondaryDir') {

                # Find the recognised secondary direction
                $recognised = $self->ivShow('combRevDirHash', $dir);
                # Convert that into the custom abbreviated direction
                return $self->ivShow('secondaryAbbrevHash', $recognised);

            # If it's a recognised relative direction...
            } elsif ($type eq 'relativeDir') {

                # $dir is a value in $self->relativeDirHash; find the corresponding key
                %revHash = reverse $self->relativeDirHash;
                $index = $revHash{$dir};
                if (defined $index) {

                    # Convert it into the abbreviated relative direction
                    return ($self->ivShow('relativeAbbrevHash', $index));
                }
            }
        }

        # Return the direction, unmodified
        return $dir;
    }

    sub unabbrevDir {

        # Can be called by anything
        #
        # Given an abbreviated custom primary direction, returns the corresponding unabbreviated
        #   direction (e.g. converts 'n' to 'nord')
        #
        # Given a recognised abbreviated secondary direction, returns the corresponding
        #   unabbreviated direction
        #       (e.g. converts 'o' to 'out')
        #
        # Given a recognised abbreviated relative direction, returns the corresponding
        #   unabbreviated direction
        #       (e.g. converts 'forward' to 'fw')
        #
        # Otherwise, returns the direction unmodified
        #
        # Expected arguments
        #   $dir    - The standard, custom primary/secondary or relative direction to unabbreviate
        #
        # Return values
        #   'undef' on improper arguments
        #   The unabbreviated (or original) direction, otherwise

        my ($self, $dir, $check) = @_;

        # Local variables
        my (
            $type, $standard, $recognised, $index,
            %revHash,
        );

        # Check for improper arguments
        if (! defined $dir || defined $check) {

            return $axmud::CLIENT->writeImproper($self->_objClass . '->unabbrevDir', @_);
        }

        $type = $self->ivShow('combDirHash', $dir);
        if (defined $type) {

            # If it's an abbreviated custom primary direction...
            if (defined $type && $type eq 'primaryAbbrev') {

                # Find the standard primary direction
                $standard = $self->ivShow('combRevDirHash', $dir);
                # Convert that into the custom unabbreviated direction
                return $self->ivShow('primaryDirHash', $standard);

            # If it's a recognised abbreviated secondary direction...
            } elsif (defined $type && $type eq 'secondaryAbbrev') {

                # Find the recognised secondary direction
                $recognised = $self->ivShow('combRevDirHash', $dir);
                # Convert that into the recognised unabbreviated direction
                return $self->ivShow('secondaryDirHash', $recognised);

            # If it's a recognised abbreviated relative direction...
            } elsif ($type eq 'relativeDir') {

                # $dir is a value in $self->relativeAbbrevHash; find the corresponding key
                %revHash = reverse $self->relativeAbbrevHash;
                $index = $revHash{$dir};
                if (defined $index) {

                    # Convert it into the unabbreviated relative direction
                    return ($self->ivShow('relativeDirHash', $index));
                }
            }
        }

        # Return the direction, unmodified
        return $dir;
    }

    ##################
    # Accessors - set

    ##################
    # Accessors - get

    sub name
        { $_[0]->{name} }
    sub language
        { $_[0]->{language} }
    sub nounPosn
        { $_[0]->{nounPosn} }

    sub definiteList
        { my $self = shift; return @{$self->{definiteList}}; }
    sub indefiniteList
        { my $self = shift; return @{$self->{indefiniteList}}; }
    sub andList
        { my $self = shift; return @{$self->{andList}}; }
    sub orList
        { my $self = shift; return @{$self->{orList}}; }

    sub numberHash
        { my $self = shift; return %{$self->{numberHash}}; }

    sub timeHash
        { my $self = shift; return %{$self->{timeHash}}; }
    sub timePluralHash
        { my $self = shift; return %{$self->{timePluralHash}}; }
    sub reverseTimeHash
        { my $self = shift; return %{$self->{reverseTimeHash}}; }
    sub reverseTimePluralHash
        { my $self = shift; return %{$self->{reverseTimePluralHash}}; }

    sub clockDayHash
        { my $self = shift; return %{$self->{clockDayHash}}; }
    sub clockHourHash
        { my $self = shift; return %{$self->{clockHourHash}}; }
    sub clockMinuteHash
        { my $self = shift; return %{$self->{clockMinuteHash}}; }

    sub constPortableTypeList
        { my $self = shift; return @{$self->{constPortableTypeList}}; }
    sub portableTypeList
        { my $self = shift; return @{$self->{portableTypeList}}; }

    sub constDecorationTypeList
        { my $self = shift; return @{$self->{constDecorationTypeList}}; }
    sub decorationTypeList
        { my $self = shift; return @{$self->{decorationTypeList}}; }

    sub guildHash
        { my $self = shift; return %{$self->{guildHash}}; }
    sub raceHash
        { my $self = shift; return %{$self->{raceHash}}; }
    sub weaponHash
        { my $self = shift; return %{$self->{weaponHash}}; }
    sub armourHash
        { my $self = shift; return %{$self->{armourHash}}; }
    sub garmentHash
        { my $self = shift; return %{$self->{garmentHash}}; }
    sub sentientHash
        { my $self = shift; return %{$self->{sentientHash}}; }
    sub creatureHash
        { my $self = shift; return %{$self->{creatureHash}}; }
    sub portableHash
        { my $self = shift; return %{$self->{portableHash}}; }
    sub decorationHash
        { my $self = shift; return %{$self->{decorationHash}}; }
    sub adjHash
        { my $self = shift; return %{$self->{adjHash}}; }

    sub portableTypeHash
        { my $self = shift; return %{$self->{portableTypeHash}}; }
    sub decorationTypeHash
        { my $self = shift; return %{$self->{decorationTypeHash}}; }

    sub pluralEndingHash
        { my $self = shift; return %{$self->{pluralEndingHash}}; }
    sub reversePluralEndingHash
        { my $self = shift; return %{$self->{reversePluralEndingHash}}; }
    sub pluralNounHash
        { my $self = shift; return %{$self->{pluralNounHash}}; }
    sub reversePluralNounHash
        { my $self = shift; return %{$self->{reversePluralNounHash}}; }

    sub adjEndingHash
        { my $self = shift; return %{$self->{adjEndingHash}}; }
    sub reverseAdjEndingHash
        { my $self = shift; return %{$self->{reverseAdjEndingHash}}; }
    sub declinedAdjHash
        { my $self = shift; return %{$self->{declinedAdjHash}}; }
    sub reverseDeclinedAdjHash
        { my $self = shift; return %{$self->{reverseDeclinedAdjHash}}; }

    sub pseudoNounHash
        { my $self = shift; return %{$self->{pseudoNounHash}}; }
    sub pseudoAdjHash
        { my $self = shift; return %{$self->{pseudoAdjHash}}; }
    sub pseudoObjHash
        { my $self = shift; return %{$self->{pseudoObjHash}}; }

    sub deathWordHash
        { my $self = shift; return %{$self->{deathWordHash}}; }
    sub unknownWordHash
        { my $self = shift; return %{$self->{unknownWordHash}}; }
    sub contentsLinesHash
        { my $self = shift; return %{$self->{contentsLinesHash}}; }
    sub ignoreWordHash
        { my $self = shift; return %{$self->{ignoreWordHash}}; }

    sub primaryDirHash
        { my $self = shift; return %{$self->{primaryDirHash}}; }
    sub primaryAbbrevHash
        { my $self = shift; return %{$self->{primaryAbbrevHash}}; }
    sub primaryOppHash
        { my $self = shift; return %{$self->{primaryOppHash}}; }
    sub primaryOppAbbrevHash
        { my $self = shift; return %{$self->{primaryOppAbbrevHash}}; }

    sub secondaryDirList
        { my $self = shift; return @{$self->{secondaryDirList}}; }
    sub secondaryDirHash
        { my $self = shift; return %{$self->{secondaryDirHash}}; }
    sub secondaryAbbrevHash
        { my $self = shift; return %{$self->{secondaryAbbrevHash}}; }
    sub secondaryOppHash
        { my $self = shift; return %{$self->{secondaryOppHash}}; }
    sub secondaryOppAbbrevHash
        { my $self = shift; return %{$self->{secondaryOppAbbrevHash}}; }
    sub secondaryAutoHash
        { my $self = shift; return %{$self->{secondaryAutoHash}}; }

    sub relativeDirHash
        { my $self = shift; return %{$self->{relativeDirHash}}; }
    sub relativeAbbrevHash
        { my $self = shift; return %{$self->{relativeAbbrevHash}}; }

    sub speedDirHash
        { my $self = shift; return %{$self->{speedDirHash}}; }
    sub speedModifierHash
        { my $self = shift; return %{$self->{speedModifierHash}}; }

    sub combNounHash
        { my $self = shift; return %{$self->{combNounHash}}; }
    sub combAdjHash
        { my $self = shift; return %{$self->{combAdjHash}}; }
    sub combDirHash
        { my $self = shift; return %{$self->{combDirHash}}; }
    sub combOppDirHash
        { my $self = shift; return %{$self->{combOppDirHash}}; }
    sub combRevDirHash
        { my $self = shift; return %{$self->{combRevDirHash}}; }
}

# Package must return a true value
1
