Pod::Spec.new do |s|
    s.name             = 'Xmpp.swift'
    s.version          = '1.0.0'
    s.summary          = 'A tiny xmpp client written in swift.'
    s.homepage         = 'https://github.com/BiAtoms/Xmpp.swift'
    s.license          = { :type => 'MIT', :file => 'LICENSE' }
    s.author           = { 'Orkhan Alikhanov' => 'orkhan.alikhanov@gmail.com' }
    s.source           = { :git => 'https://github.com/BiAtoms/Xmpp.swift.git', :tag => s.version.to_s }
    s.module_name      = 'XmppSwift'

    s.ios.deployment_target = '8.0'
    s.osx.deployment_target = '10.9'
    s.tvos.deployment_target = '9.0'
    s.source_files = 'Sources/*.swift'
    s.dependency 'Socket.swift', '~> 2.0'
    s.dependency 'Xml.swift', '~> 1.0'
end
