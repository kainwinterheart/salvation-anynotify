use ExtUtils::MakeMaker;

WriteMakefile (
    NAME => 'Salvation::AnyNotify',
    VERSION_FROM => 'lib/Salvation/AnyNotify.pm',
    ABSTRACT => 'Notification framework',
    AUTHOR => [ 'Gennadiy Filatov <gfilatov@cpan.org>' ],
    LICENSE => 'mit',
    PREREQ_PM => {
        'Salvation::TC' => '0.11',
        'Salvation::Method::Signatures' => '0.02',
        'Salvation::DaemonDecl' => 0,
        'AnyEvent' => 0,
        'String::CamelCase' => 0,
        'YAML' => 0,
        'File::Slurp' => 0,
        'File::HomeDir' => 0,
        'URI' => 0,
        'Net::Graphite::Reader' => 0,
        'Sub::Recursive' => 0,
        'Twiggy' => 0,
        'Plack' => 0,
        'JSON' => 0,
        'bignum' => 0,
    },
    META_MERGE => {
    "meta-spec" => { version => 2 },
        resources => {
            repository => {
                type => 'git',
                url => 'https://github.com/kainwinterheart/salvation-anynotify.git',
                web => 'https://github.com/kainwinterheart/salvation-anynotify',
                bugtracker => 'https://github.com/kainwinterheart/salvation-anynotify/issues',
            },
        },
    },
);

exit 0;

__END__
