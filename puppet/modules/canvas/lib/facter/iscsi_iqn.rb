require 'facter'
Facter.add(:iscsi_iqn) do
  setcode do
    file = '/etc/iscsi/initiatorname.iscsi'
    if File.exists?(file)
      Facter::Util::Resolution.exec("/bin/cat #{file} | grep ^InitiatorName=").split('=').last
    else
     ''
    end
  end
end
