requires 'Exporter'                      => '0';
requires 'parent'                        => '0';
requires 'JSON' => 2;
requires 'Scalar::Util' => 0;
requires 'Test::More' => '0.98';

on 'configure' => sub {
    requires 'Module::Build' => '0.38';
    requires 'Module::Build::Pluggable::GithubMeta';
    requires 'Module::Build::Pluggable::CPANfile';
    requires 'Module::Build::Pluggable::DistTestLibCoreOnly' => '0.0.4';
};

on 'test' => sub {
    requires 'Test::More' => '0.98';
    requires 'Test::Requires' => 0;
};
