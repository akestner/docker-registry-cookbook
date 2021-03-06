name                'docker-registry'
maintainer          'Alex Kestner'
maintainer_email    'akestner@healthguru.com'
license             'Apache 2.0'
description         'Installs and configures docker-registry, with an optional nginx frontend.'
version             '0.0.5'

supports 'ubuntu'

depends 'openssl'
depends 'application', '~> 3.0'
depends 'application_nginx'
depends 'application_python'

