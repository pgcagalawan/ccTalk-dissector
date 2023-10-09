--[[
    ccTalk Protocol over USB HID
    Author: Paks
]]
cctalk_usbhid_protocol = Proto("ccTalk_USBHID",  "ccTalk HID Protocol")

local command_header = {
    [0]="Response",
    [1]="Reset device",
    [4]="Request comms revision",
    [60]="Modify audit counter",
    [62]="Request PCB id",
    [63]="Echo test",
    [68]="Park motor",
    [76]="Request bootloader software revision",
    [77]="Write peripheral data block",
    [78]="Read peripheral data block",
    [82]="Request coins in by type",
    [84]={
        [0]="Request controller manifest: Query fitted",
        [1]="Request controller manifest: Software revision",
        [2]="Request controller manifest: Manufacturer id",
        [3]="Request controller manifest: Equipment category",
        [4]="Request controller manifest: Product code",
        [5]="Request controller manifest: Serial number",
        [6]="Request controller manifest: Level sensor",
        [7]="Request controller manifest: Hopper extended coin id",
        [8]="Request controller manifest: Hopper capacity",
        [9]="Request controller manifest: Bootloader revision",
        [11]="Request controller manifest: Database version",
        [12]="Request controller manifest: Build code",
        [13]="Request controller manifest: PCB id"
    },
    [85]="Dispense hopper pattern",
    [86]="Request audit counter",
    [87]="Clear audit counter",
    [96]={
        [243]="Request coin issue",
        [244]="Request currency code",
        [245]="Remove all coin signatures",
        [248]="Request extended coin id",
        [249]="Remove coin signature",
        [253]="End packet upload & program",
        [254]="Upload packet data",
        [255]="Begin packet upload"
    },
    [100]={
        [150]="Request system event log",
        [151]="Direct pay",
        [153]="Recalibrate door sensor",
        [156]="Request dispense failure code",
        [157]="Request non-fatal error buffer",
        [158]="Fast poll opto states",
        [165]="Sample motor performance",
        [166]="Prime active cashbox",
        [167]="Read debris flap control",
        [168]="Modify debris flap control",
        [169]="Exit bulk refill mode",
        [170]="Enter bulk refill mode",
        [171]="Perform internal test cycle",
        [172]="Read electrical parameters",
        [175]="Modify build record",
        [176]="Notify part replacement",
        [177]="Request service report",
        [179]="Set host identification strings",
        [180]="Read change calculation parameters",
        [181]="Set change calculation parameters",
        [182]="Force exception",
        [183]="Nudge motor",
        [184]="Test front-panel display",
        [186]="Read active cashbox look-ahead buffer",
        [189]="Purge active cashbox to exit cup",
        [192]="Purge by denomination to exit cup",
        [193]="Request coins out by type",
        [198]="Read SDD file",
        [199]="Request master coin channel id",
        [200]="Request retail fault code"
    },
    [104]="Request service status",
    [114]="Request USB id",
    [115]="Request real time clock",
    [116]="Modify real time clock",
    [117]="Request cashbox value",
    [118]="Modify cashbox value",
    [119]="Request hopper balance",
    [120]="Modify hopper balance",
    [121]="Purge hopper",
    [123]="Request activity register",
    [124]="Verify money out",
    [125]="Pay money out",
    [126]="Clear money counters",
    [127]="Request money out",
    [128]="Request money in",
    [138]="Finish firmware upgrade",
    [139]="Begin firmware upgrade",
    [140]="Upload firmware",
    [141]="Request firmware upgrade capability",
    [146]="Operate bi-directional motors",
    [165]="Modify variable set",
    [170]="Request base year",
    [174]="Request payout float",
    [175]="Modify payout float",
    [184]="Request coin id",
    [192]="Request build code",
    [195]="Request last modification date",
    [196]="Request creation date",
    [197]="Calculate ROM checksum",
    [214]="Write data block",
    [215]="Read data block",
    [216]="Request data storage availability",
    [230]="Request inhibit status",
    [231]="Modify inhibit status",
    [236]="Read opto states",
    [237]="Read input lines",
    [240]="Test solenoids",
    [241]="Request software revision",
    [242]="Request serial number",
    [244]="Request product code",
    [245]="Request equipment category id",
    [246]="Request manufacturer id",
    [247]="Request variable set",
    [254]="Simple poll"
}

-- The ccTalk packet format is…
-- [ destination address ] [ data length ] [ source address ] [ command header z] [ data ]… [checksum ]

local dst   = ProtoField.uint8("cctalk_usbhid.dst",   "Destination",   base.DEC)
local len   = ProtoField.uint8("cctalk_usbhid.len",   "Length",   base.DEC)
local src   = ProtoField.uint8("cctalk_usbhid.src",   "Source",   base.DEC)
local cmd   = ProtoField.string("cctalk_usbhid.cmd",   "Command Header",   base.ASCII)
local data   = ProtoField.bytes("cctalk_usbhid.data",   "Data",   base.NONE)
local checksum   = ProtoField.int8("cctalk_usbhid.checksum",   "Checksum",   base.DEC)


cctalk_usbhid_protocol.fields = { dst, len, src, cmd, data, checksum }

function cctalk_usbhid_protocol.dissector(buffer, pinfo, tree)
  length = buffer:len()
  if length == 0 then return end

  pinfo.cols.protocol = cctalk_usbhid_protocol.name

  local subtree = tree:add(cctalk_usbhid_protocol, buffer(), "ccTalk")
  subtree:add(dst, buffer(0,1))
  subtree:add(len, buffer(1,1))
  subtree:add(src, buffer(2,1))

  --subtree:add(cmd, buffer(3,1)):append_text(" (" .. command_header[buffer(3,1):uint()] .. ")")
  if type(command_header[buffer(3,1):uint()]) == "table" then
    subtree:add(cmd, command_header[buffer(3,1):uint()][buffer(4,1):uint()]):append_text(" (" .. buffer(3,1):uint() .. ":" .. buffer(4,1):uint() .. ")")
  else 
    subtree:add(cmd, command_header[buffer(3,1):uint()]):append_text(" (" .. buffer(3,1):uint() .. ")")
  end

  if buffer(1,1):uint() ~= 0 then
    subtree:add(data, buffer(4,buffer(1,1):uint()))
    subtree:add(checksum, buffer(4+buffer(1,1):uint(),1))
  else
    subtree:add(checksum, buffer(4,1))
  end

end

DissectorTable.get("usb.interrupt"):add(0x0003, cctalk_usbhid_protocol)