use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Data::Validate::Domain',
    VERSION_FROM      => 'lib/Data/Validate/Domain.pm', # finds $VERSION
    LICENSE		=> 'perl',
    PREREQ_PM         => {
		                        Test::More	=>	0,
		                        Net::Domain::TLD => 1.62,
				}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Data/Validate/Domain.pm', # retrieve abstract from module
       AUTHOR         => 'Neil Neely <neil@neely.cx>') : ()),
    META_MERGE => {
        'meta-spec' => { version => 2 },
        resources => {
            repository => {
                type => 'git',
                url  => 'https://github.com/neilneely/Data-Validate-Domain.git',
                web  => 'https://github.com/neilneely/Data-Validate-Domain',
            },
        },
    },
);
