object Form2: TForm2
  Left = 0
  Top = 0
  Caption = 'Form2'
  ClientHeight = 229
  ClientWidth = 539
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  OnCreate = FormCreate
  TextHeight = 15
  object LabelFolderPath: TLabel
    Left = 16
    Top = 11
    Width = 60
    Height = 15
    Caption = 'Folder Path'
  end
  object SpeedButtonFolderBrowse: TSpeedButton
    Left = 503
    Top = 8
    Width = 23
    Height = 22
    ImageIndex = 0
    Images = ImageList1
    OnClick = SpeedButtonFolderBrowseClick
  end
  object SpeedButtonMoveFolderBrowse: TSpeedButton
    Left = 503
    Top = 113
    Width = 23
    Height = 22
    ImageIndex = 0
    Images = ImageList1
    OnClick = SpeedButtonMoveFolderBrowseClick
  end
  object SpeedButtonErrorFolderBrowse: TSpeedButton
    Left = 503
    Top = 150
    Width = 23
    Height = 22
    ImageIndex = 0
    Images = ImageList1
    OnClick = SpeedButtonErrorFolderBrowseClick
  end
  object SpeedButtonSave: TSpeedButton
    Left = 457
    Top = 189
    Width = 32
    Height = 32
    ImageIndex = 1
    Images = ImageList1
    OnClick = SpeedButtonSaveClick
  end
  object SpeedButtonCancel: TSpeedButton
    Left = 495
    Top = 189
    Width = 32
    Height = 32
    ImageIndex = 2
    Images = ImageList1
    OnClick = SpeedButtonCancelClick
  end
  object EditFolderPath: TEdit
    Left = 94
    Top = 8
    Width = 403
    Height = 23
    TabOrder = 0
  end
  object CheckBoxLogFile: TCheckBox
    Left = 16
    Top = 48
    Width = 97
    Height = 17
    Caption = 'Log file'
    TabOrder = 1
    OnClick = CheckBoxLogFileClick
  end
  object CheckBoxErrorFile: TCheckBox
    Left = 16
    Top = 152
    Width = 97
    Height = 17
    Caption = 'Error file'
    TabOrder = 2
    OnClick = CheckBoxErrorFileClick
  end
  object EditMovePath: TEdit
    Left = 94
    Top = 113
    Width = 403
    Height = 23
    TabOrder = 3
  end
  object EditErrorPath: TEdit
    Left = 94
    Top = 149
    Width = 403
    Height = 23
    TabOrder = 4
  end
  object RadioButtonDelete: TRadioButton
    Left = 96
    Top = 48
    Width = 113
    Height = 17
    Caption = 'Delete'
    TabOrder = 5
    OnClick = RadioButtonDeleteClick
  end
  object RadioButtonMove: TRadioButton
    Left = 96
    Top = 80
    Width = 113
    Height = 17
    Caption = 'Move'
    TabOrder = 6
    OnClick = RadioButtonMoveClick
  end
  object ImageList1: TImageList
    ColorDepth = cd32Bit
    Left = 8
    Top = 192
    Bitmap = {
      494C010103000800040010001000FFFFFFFF2110FFFFFFFFFFFFFFFF424D3600
      0000000000003600000028000000400000001000000001002000000000000010
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000ED9A67CFF302419FFF1EB
      DDFFEDE8DAFFEDE8DAFFEDE8DAFFEDE8DAFFEDE8DAFFEDE8DAFFEDE8DAFFEDE8
      DAFFEBE6D8FF7B7874FFF1BA8CFF1A1005FC0000000000000000000000000000
      00000102072C363DDDEF4149FFFF3D45FFFF3C44FBFF3F47FFFF4149FFFF171A
      609D000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      000000000000000000000000000000000000000000000000000C000001110000
      0111000001110000011100000111000001110000011100000111000001110000
      0111000001100000000000000000000000000000000EE1AC81FF31251AFFF6F2
      E3FF2A2926FF2A2927FF2A2927FF2A2927FF2A2927FF2A2927FF2A2927FF2A29
      27FF686660FF807D77FFF8BF90FF1B1007F3000000000000000000000000282D
      A3CD3D45FFFF3C44FBFF3C44FBFF3C44FBFF3C44FBFF3C44FBFF3C44FBFF3C44
      FBFF424BFFFF0101052700000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      00000000000000000000000000000000000001070A3531D1FFFF31C9FFFF31C9
      FFFF31C9FFFF31C9FFFF31C9FFFF31C9FFFF31C9FFFF31C9FFFF31C9FFFF31C9
      FFFF34D4FFFF218AB4D700000000000000000000000EE1AC81FF31251AFFF7F2
      E4FF918E85FF918E85FF918E85FF918E85FF918E85FF918E85FF918E85FF918E
      85FFAFABA1FF807C77FFF8BF90FF1B1007F30000000000000000343BD5EB3C44
      FBFF3C44FBFF3C44FBFF3C44FBFF3C44FBFF3C44FBFF3C44FBFF3C44FBFF3C44
      FBFF3C44FBFF4048FFFF01010525000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000005083226BEFFFF30C4FFFF30C4
      FFFF30C4FFFF30C4FFFF30C4FFFF30C4FFFF30C4FFFF30C4FFFF30C4FFFF30C4
      FFFF30C5FFFF33CEFFFF00000000000000000000000EE1AC81FF31251AFFF9F3
      E5FFFFFFF9FFFFFFF9FFFFFFF9FFFFFFF9FFFFFFF9FFFFFFF9FFFFFFF9FFFFFF
      F9FFFFFFF2FF807C77FFF8BF90FF1B1007F30000000011144A8B3C44FBFF3C44
      FBFF3C44FBFF333BFBFF333BFBFF3C44FBFF3C44FBFF3A42FBFF3B43FBFF3B43
      FBFF3C44FBFF3C44FBFF424BFFFF000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000006083212A8F2FF31C6FFFF30C4
      FFFF30C4FFFF30C4FFFF30C4FFFF30C4FFFF30C4FFFF30C4FFFF30C4FFFF30C4
      FFFF30C4FFFF31C9FFFF0000000F000000000000000EE0AB80FF9A7D65FFF0EB
      DDFF8D8A81FF8D8A82FF8D8A82FF8D8A82FF8D8A82FF8D8A82FF8D8A82FF8D8A
      82FFADA99FFF807C77FFF8BF90FF1B1007F300000000414AFFFF3C44FBFF3C44
      FBFF3139FBFFE4EEFEFFE5EFFEFF323AFBFF3941FBFF98A1FDFFDEE8FEFF8D96
      FDFF3B43FBFF3C44FBFF3C44FBFF171A62A00000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000006083210A6F1FF32C7FFFF30C4
      FFFF30C4FFFF30C4FFFF30C4FFFF30C4FFFF30C4FFFF30C4FFFF30C4FFFF30C4
      FFFF30C4FFFF30C4FFFF071C2461000000000000000EE1AC81FF33261BFFF6F1
      E3FF2A2927FF2B2A27FF2B2A27FF2B2A27FF2B2A27FF2B2A27FF2B2A27FF2B2A
      27FF686660FF807D77FFF8BF90FF1B1007F3040512463C44FBFF3C44FBFF3A42
      FBFFC7D1FEFFD5DFFEFFD5DFFEFFE3EDFEFF929BFDFFD6E0FEFFD5DFFEFFDEE8
      FEFF3B43FBFF3C44FBFF3C44FBFF414AFFFF0000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000006083213A8F3FF27BAF8FF32C7
      FFFF30C4FFFF30C4FFFF30C4FFFF30C4FFFF30C4FFFF30C4FFFF30C4FFFF30C4
      FFFF30C4FFFF30C4FFFF31C4FAFD0105062A0000000EE1AC81FF281D14FFEEE9
      DCFFE9E5D8FFE9E5D8FFE9E5D8FFE9E5D8FFE9E5D8FFE9E5D8FFE9E5D8FFE9E5
      D8FFE7E3D6FF6B6A67FFFAC091FF1B1007F322278FC13C44FBFF3C44FBFF3C44
      FBFF333BFBFFE3EEFEFFD5DFFEFFD5DFFEFFD5DFFEFFD5DFFEFFD6E0FEFF98A1
      FDFF3A42FBFF3C44FBFF3C44FBFF3F47FFFF0000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000006083213A9F3FF1CACEFFF32C7
      FFFF30C4FFFF30C4FFFF30C4FFFF30C4FFFF30C4FFFF30C4FFFF30C4FFFF30C4
      FFFF30C4FFFF30C4FFFF34D5FFFF0D3849890000000EE0AB80FFEDB688FFC897
      6EFFC8986FFFC8986FFFC8986FFFC8986FFFC8986FFFC8986FFFC8986FFFC898
      6FFFC8986FFFD8A579FFE6B185FF1B1007F33C43F6FD3C44FBFF3C44FBFF3C44
      FBFF3C44FBFF2F37FBFFDDE7FEFFD5DFFEFFD5DFFEFFD5DFFEFF929BFDFF3941
      FBFF3C44FBFF3C44FBFF3C44FBFF3C44FBFF0000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000006083213A9F3FF109EE6FF22B3
      F4FF31C6FFFF31C6FFFF31C6FFFF31C6FFFF31C6FFFF31C6FFFF31C6FFFF31C6
      FFFF31C5FFFF32C9FFFF33CFFFFF33D2FFFF0000000EE0AB80FFE3AE82FFE3AE
      82FFE3AE82FFE3AE82FFE3AE82FFE3AE82FFE3AE82FFE3AE82FFE3AE82FFE3AE
      82FFE3AE82FFE3AE82FFE7B286FF1B1007F33238D0E93C44FBFF3C44FBFF3C44
      FBFF3940FBFF98A2FDFFD5DFFEFFD5DFFEFFD5DFFEFFD5DFFEFFE3EDFEFF323A
      FBFF3C44FBFF3C44FBFF3C44FBFF3D45FFFF0000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000006083213A9F3FF12A0E8FF13A2
      E9FF1AAAEEFF1AAAEEFF1AAAEEFF1AAAEEFF1AAAEEFF1AAAEEFF1AAAEEFF1AAA
      EEFF1BB4FCFF0B445FA0030C104002090C380000000EE0AB80FFE3AE82FFE3AE
      82FFE3AE82FFE3AE82FFE3AE82FFE3AE82FFE3AE82FFE3AE82FFE3AE82FFE3AE
      82FFE3AE82FFE3AE82FFE7B286FF1B1007F3111347883C44FBFF3C44FBFF3C44
      FBFF8F98FDFFD6E0FEFFD5DFFEFFD5DFFEFFDDE7FEFFD5DFFEFFD5DFFEFFE5EF
      FEFF333BFBFF3C44FBFF3C44FBFF414AFFFF0000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000006083213A9F3FF12A1E8FF12A1
      E8FF12A1E8FF12A1E8FF12A1E8FF12A5EEFF13A5EEFF13A5EEFF13A5EEFF13A5
      EEFF15B3FFFF052B3F8600000000000000000000000EE0AB80FFE3AE82FFE3AE
      82FFE4AF83FFE4AF83FFE4AF83FFE4AF83FFE4AF83FFE4AF83FFE4AF83FFE4AF
      83FFE3AE82FFE3AE82FFE7B286FF1B1007F30000000B3D46FFFF3C44FBFF3C44
      FBFF848DFCFFD7E1FEFFD6E0FEFF99A2FDFF2F37FBFFE3EEFEFFD5DFFEFFE4EE
      FEFF333BFBFF3C44FBFF3C44FBFF373DE3F30000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000006083213A9F3FF12A1E8FF12A1
      E8FF12A1E8FF12A1E8FF12A5EEFF108DCBEF108AC7EC108AC7EC108AC7EC108A
      C7EC1091D3EB0216205F00000000000000000000000EE0AB80FFE3AE82FFE1AC
      81FF322419FF33261BFF33261BFF33251AFF36291EFF36291EFF372A1FFF3629
      1EFF775B43FFE4AF83FFE7B286FF1B1007F3000000003B43F4FB3C44FBFF3C44
      FBFF3A42FBFF848DFCFF8F98FDFF3840FBFF3C44FBFF333BFBFFC7D1FDFF3139
      FBFF3C44FBFF3C44FBFF3D45FEFF010105270000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      00000000000000000000000000000000000000070A3514AFFBFF13A5EEFF13A5
      EEFF13A5EEFF13A7F0FF010A0E40000000000000000000000000000000000000
      0000000000000000000000000000000000000000000EE0AB80FFE3AE82FF543C
      28FFFFFFF7FFF8F3E4FFF8F3E4FFFFFFF7FF2D281EFF6B6251FF1D1B16FF746A
      58FF11130FFFF6BC8DFFE6B286FF1D1107F600000000000000064149FFFF3C44
      FBFF3C44FBFF3C44FBFF3C44FBFF3C44FBFF3C44FBFF3C44FBFF3A42FBFF3C44
      FBFF3C44FBFF3C44FBFF292FAAD2000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      000000000000000000000000000000000000000203211084BFE4108AC7EC108A
      C7EC108AC7EC1092D3EC00000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000EE0AB80FFE3AE82FF5A40
      2CFFFFF9EAFFECE7D9FFECE7D9FFFFFAEBFF2A251CFF423C2FFFF8ECDCFF534B
      3DFF74664FFFE4AE82FFF2B179FF0000007B0000000000000000020209324149
      FFFF3C44FBFF3C44FBFF3C44FBFF3C44FBFF3C44FBFF3C44FBFF3C44FBFF3C44
      FBFF3C44FBFF343BD3E900000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000EE5AE83FFE7B184FF5C41
      2DFFFFFEEEFFF1EBDDFFF1EBDDFFFFFFF0FF2B261DFF5D5546FF2B2825FF6960
      4FFF131510FFFEC494FF25160AFF000000000000000000000000000000000000
      00073C43F1F93D46FFFF3C44FBFF3C44FBFF3C44FBFF3C44FBFF3C44FBFF414A
      FFFF12144A8A0000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      000000000000000000000000000000000000000000010E0B08FF0F0B08FF0604
      02FF111110FF10100FFF10100FFF111110FF020201FF080705FF0C0B09FF0807
      05FF010100FF110B07FF00000011000000000000000000000000000000000000
      0000000000000000000E101447873137CCE63A42F3FB23278FC0040513470000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      000000000000000000000000000000000000424D3E000000000000003E000000
      2800000040000000100000000100010000000000800000000000000000000000
      000000000000000000000000FFFFFF0000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      000000000000}
  end
end