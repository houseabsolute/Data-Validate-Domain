use strict;
use warnings;

use Test::More;

use Data::Validate::Domain;

is( is_domain_label('www'),   'www',   'is_domain_label www' );
is( is_domain_label('w-w'),   'w-w',   'is_domain_label w-w' );
is( is_domain_label('neely'), 'neely', 'is_domain_label neely' );
is( is_domain_label('com'),   'com',   'is_domain_label com' );
is( is_domain_label('COM'),   'COM',   'is_domain_label COM' );
is( is_domain_label('128'),   '128',   'is_domain_label 128' );
ok( !is_domain_label(q{}),    'is_domain_label ' );
ok( !is_domain_label('-bob'), 'is_domain_label -bob' );
ok( !is_domain_label("bengali-\x{09ea}"),
    'bengali 4 is not accepted in domain label' );

#70 character label
isnt(
    '1234567890123456789012345678901234567890123456789012345678901234567890',
    is_domain_label(
        '1234567890123456789012345678901234567890123456789012345678901234567890'
    ),
    'is_domain_label 1234567890123456789012345678901234567890123456789012345678901234567890'
);

is( is_domain('www.neely.cx'), 'www.neely.cx', 'is_domain www.neely.cx' );
ok( !is_domain('www.neely.cx.'),   'is_domain www.neely.cx.' );
ok( !is_domain('www.neely.cx...'), 'is_domain www.neely.cx...' );
ok( !is_domain('www.neely.lkj'),   'is_domain www.neely.lkj' );
is( is_domain('neely.cx'),      'neely.cx',      'is_domain neely.cx' );
is( is_domain('test-neely.cx'), 'test-neely.cx', 'is_domain test-neely.cx' );
is( is_domain('aa.com'),        'aa.com',        'is_domain aa.com' );
is( is_domain('A-A.com'),       'A-A.com',       'is_domain A-A.com' );
is( is_hostname('aa.com'),      'aa.com',        'is_hostname aa.com' );
is( is_hostname('aa.bb'),       'aa.bb',         'is_hostname aa.bb' );
is( is_hostname('aa'),          'aa',            'is_hostname aa' );
ok( !is_domain('216.17.184.1'),  'is_domain 216.17.184.1' );
ok( !is_domain('test_neely.cx'), 'is_domain test_neely.cx' );
ok( !is_domain('.neely.cx'),     'is_domain .neely.cx' );
ok( !is_domain('-www.neely.cx'), 'is_domain -www.neely.cx' );
ok( !is_domain('a'),             'is_domain a' );
ok( !is_domain('.'),             'is_domain .' );
ok( !is_domain('com.'),          'is_domain com.' );
ok( !is_domain('com'),           'is_domain com' );
ok( !is_domain('net'),           'is_domain net' );
ok( !is_domain('uk'),            'is_domain uk' );
is( is_domain('co.uk'), 'co.uk', 'is_domain co.uk' );
ok( !is_domain("bengali-\x{09ea}.com"),
    'bengali 4 is not accepted in domain' );

#280+ character domain
ok(
    !is_domain(
        '123456789012345678901234567890123456789012345678901234567890.1234567890123456789012345678901234567890.12345678901234567890123456789012345678901234567890.12345678901234567890123456789012345678901234567890.12345678901234567890123456789012345678901234567890.123456789012345678901234567890.com'
    ),
    'is_domain 123456789012345678901234567890123456789012345678901234567890.1234567890123456789012345678901234567890.12345678901234567890123456789012345678901234567890.12345678901234567890123456789012345678901234567890.12345678901234567890123456789012345678901234567890.123456789012345678901234567890.com'
);

#Some additional tests for options
is(
    is_domain( 'myhost.neely', { domain_private_tld => { 'neely' => 1 } } ),
    'myhost.neely',
    'is_domain myhost.neely w/domain_private_tld option'
);
ok( !is_domain('myhost.neely'), 'is_domain myhost.neely' );
is(
    is_domain( 'com', { domain_allow_single_label => 1 } ),
    'com',
    'is_domain com w/domain_allow_single_label option'
);
is(
    is_domain(
        'neely', {
            domain_allow_single_label => 1,
            domain_private_tld        => { 'neely' => 1 }
        }
    ),
    'neely',
    'is_domain neely w/domain_private_tld  and domain_allow_single_label option'
);
ok( !is_domain('neely'), 'is_domain neely' );
isnt( is_hostname('_spf'), '_spf', 'is_hostname("_spf"' );
is(
    is_hostname( '_spf', { domain_allow_underscore => 1 } ),
    '_spf',
    'is_hostname("_spf", {domain_allow_underscore = 1}'
);

ok( !is_domain("example\n.com"),   'is_domain( "example\n.com")' );
ok( !is_domain_label("example\n"), 'is_domain_label( "example\n")' );

#precompiled regex format
is(
    is_domain( 'myhost.neely', { domain_private_tld => qr/^neely$/ } ),
    'myhost.neely',
    'is_domain myhost.neely w/domain_private_tld option - precompiled regex'
);
ok(
    !is_domain( 'myhost.neely', { domain_private_tld => qr/^intra$/ } ),
    'is_domain myhost.neely w/domain_private_tld option - precompiled regex looking for intra'
);

my $obj = Data::Validate::Domain->new();
is( $obj->is_domain('co.uk'), 'co.uk', '$obj->is_domain co.uk' );

my $private_tld_obj = Data::Validate::Domain->new(
    domain_private_tld => {
        neely   => 1,
        neely72 => 1,
    },
);
is(
    $private_tld_obj->is_domain('myhost.neely'),
    'myhost.neely',
    '$private_tld_obj->is_domain myhost.neely'
);
is(
    $private_tld_obj->is_domain('myhost.neely72'),
    'myhost.neely72',
    '$private_tld_obj->is_domain myhost.neely72'
);
ok(
    !$private_tld_obj->is_domain('myhost.intra'),
    '$private_tld_obj->is_domain myhost.intra'
);
ok(
    !$private_tld_obj->is_domain('neely'),
    '$private_tld_obj->is_domain neely'
);

my $private_single_label_tld_obj = Data::Validate::Domain->new(
    domain_allow_single_label => 1,
    domain_private_tld        => {
        neely => 1,
    },
);

is(
    $private_single_label_tld_obj->is_domain('neely'),
    'neely',
    '$private_single_label_tld_obj->is_domain neely'
);
is(
    $private_single_label_tld_obj->is_domain('NEELY'),
    'NEELY',
    '$private_single_label_tld_obj->is_domain NEELY'
);
is(
    $private_single_label_tld_obj->is_domain('neely.cx'),
    'neely.cx',
    '$private_single_label_tld_obj->is_domain neely.cx'
);

#precompiled regex format
my $private_tld_obj2 = Data::Validate::Domain->new(
    domain_private_tld => qr/^(?:neely|neely72)$/,
);
is(
    $private_tld_obj2->is_domain('myhost.neely'),
    'myhost.neely',
    '$private_tld_obj2->is_domain myhost.neely'
);
is(
    $private_tld_obj2->is_domain('myhost.neely72'),
    'myhost.neely72',
    '$private_tld_obj2->is_domain myhost.neely72'
);
ok(
    !$private_tld_obj2->is_domain('myhost.intra'),
    '$private_tld_obj2->is_domain myhost.intra'
);
ok(
    !$private_tld_obj2->is_domain('neely'),
    '$private_tld_obj2->is_domain neely'
);

my $allow_underscore_obj = Data::Validate::Domain->new(
    domain_allow_underscore => 1,
);
is(
    $allow_underscore_obj->is_domain('_spf.neely.cx'),
    '_spf.neely.cx',
    '$allow_underscore_obj->is_domain _spf.neely.cx'
);
is(
    $allow_underscore_obj->is_domain('_sip._tcp.neely.cx'),
    '_sip._tcp.neely.cx',
    '$allow_underscore_obj->is_domain _sip._tcp.neely.cx'
);
is(
    $allow_underscore_obj->is_hostname('_spf'),
    '_spf',
    '$allow_underscore_obj->is_domain _spf'
);

done_testing();
