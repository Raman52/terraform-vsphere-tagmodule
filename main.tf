provider "vsphere" {
  user                 = var.vsphere_user
  password             = var.vsphere_password
  vsphere_server       = var.vsphere_server
  allow_unverified_ssl = true
}

data "vsphere_datacenter" "datacenter" {
  name = "Datacenter"
}

data "vsphere_datastore" "datastore" {
  name          = "datastore1"
  datacenter_id = data.vsphere_datacenter.datacenter.id
}

data "vsphere_resource_pool" "pool" {
  name          = "Cluster/Resources"
  datacenter_id = data.vsphere_datacenter.datacenter.id
}

data "vsphere_network" "network" {
  name          = "VM Network"
  datacenter_id = data.vsphere_datacenter.datacenter.id
}

data "vsphere_virtual_machine" "template" {
  name          = "terrav"
  datacenter_id = data.vsphere_datacenter.datacenter.id
}
resource "vsphere_tag_category" "vm_tags_category" {
  name        = "VM-Category"
  cardinality = "MULTIPLE" # Allows multiple tags per object

  associable_types = [
    "VirtualMachine"
  ]
}
resource "vsphere_tag" "environment_test" {
  name        = "test"
  category_id = vsphere_tag_category.vm_tags_category.id
  description = "Tag for environment classification"
   lifecycle {
    ignore_changes = [
      name
    ]
   }
}

resource "vsphere_tag" "owner_ramanjeet" {
  name        = "ram"
  category_id = vsphere_tag_category.vm_tags_category.id
  description = "Tag for ownership identification"
   lifecycle {
    ignore_changes = [
      name
    ]
   }
}


resource "vsphere_virtual_machine" "vm" {
  name             = var.vm_name
  resource_pool_id = data.vsphere_resource_pool.pool.id
  datastore_id     = data.vsphere_datastore.datastore.id

  num_cpus  = 1
  memory    = 4096
  guest_id  = data.vsphere_virtual_machine.template.guest_id
  scsi_type = data.vsphere_virtual_machine.template.scsi_type

  network_interface {
    network_id   = data.vsphere_network.network.id
    adapter_type = data.vsphere_virtual_machine.template.network_interface_types[0]
  }

  disk {
    label            = "Hard 1"
    size             = data.vsphere_virtual_machine.template.disks[0].size
    thin_provisioned = data.vsphere_virtual_machine.template.disks[0].thin_provisioned
    datastore_id     = data.vsphere_datastore.datastore.id
    unit_number      = 0

  }
    disk {
    label            = "Hard 2"
    size             = 20  # Set size as needed
    thin_provisioned = true  # Set thin provisioning as needed
    datastore_id     = data.vsphere_datastore.datastore.id
    unit_number      = 1
  }

  disk {
    label            = "additional-disk"
    size             = var.additional_disk_size
    eagerly_scrub    = false
    thin_provisioned = true
    unit_number      = 2
    datastore_id     = data.vsphere_datastore.datastore.id
  }

  clone {
    template_uuid = data.vsphere_virtual_machine.template.id
  }
  tags = [vsphere_tag.environment_test.id,
          vsphere_tag.owner_ramanjeet.id
   ]

  lifecycle {
    ignore_changes = [tags]
  }
}
resource "vsphere_virtual_disk" "additional_disk" {
  size      = var.additional_disk_size
  vmdk_path = "${var.vm_name}/additional-disk.vmdk"
  datastore = data.vsphere_datastore.datastore.name
}

