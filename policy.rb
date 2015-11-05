policy('bastion-host-demo') do
    ['conjurBastionServer', 'clientA', 'clientB'].each do |layerName|
        layer(layerName) do |layer|
            host_factory "#{layerName}_factory", layers: [layer], role: policy_role
        end
    end
end
