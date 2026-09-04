object FrameEtape: TFrameEtape
  Left = 0
  Top = 0
  Width = 620
  Height = 500
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -19
  Font.Name = 'Segoe UI'
  Font.Style = []
  ParentFont = False
  TabOrder = 0
  object ScrollBoxContenu: TScrollBox
    Left = 0
    Top = 0
    Width = 620
    Height = 500
    Align = alClient
    BorderStyle = bsNone
    TabOrder = 0
    DesignSize = (
      620
      500)
    object LabelTitre: TLabel
      Left = 0
      Top = 0
      Width = 7
      Height = 32
      Anchors = [akLeft, akTop, akRight]
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -24
      Font.Name = 'Segoe UI'
      Font.Style = [fsBold]
      ParentFont = False
      Visible = False
      WordWrap = True
    end
    object ImageEtape: TImage
      Left = 0
      Top = 32
      Width = 580
      Height = 200
      Anchors = [akLeft, akTop, akRight]
      Center = True
      Proportional = True
      Visible = False
    end
    object LabelTexte: TLabel
      Left = 0
      Top = 32
      Width = 6
      Height = 30
      Anchors = [akLeft, akTop, akRight]
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -21
      Font.Name = 'Segoe UI'
      Font.Style = []
      ParentFont = False
      WordWrap = True
    end
    object MemoTexteListe: TMemo
      Left = 0
      Top = 32
      Width = 580
      Height = 100
      Anchors = [akLeft, akTop, akRight]
      BorderStyle = bsNone
      Color = clBtnFace
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -21
      Font.Name = 'Segoe UI'
      Font.Style = []
      ParentFont = False
      ReadOnly = True
      ScrollBars = ssVertical
      TabOrder = 0
      Visible = False
    end
    object PanelInstruction: TPanel
      Left = 0
      Top = 140
      Width = 580
      Height = 40
      Anchors = [akLeft, akTop, akRight]
      BevelOuter = bvNone
      TabOrder = 1
      Visible = False
      object BoutonContinuer: TButton
        Left = 0
        Top = 0
        Width = 180
        Height = 36
        Caption = #201'tape suivante'
        Default = True
        TabOrder = 0
        OnClick = GererClicContinuer
      end
    end
    object PanelChoix: TPanel
      Left = 0
      Top = 140
      Width = 580
      Height = 200
      Anchors = [akLeft, akTop, akRight]
      BevelOuter = bvNone
      TabOrder = 2
      Visible = False
    end
    object PanelSaisie: TPanel
      Left = 0
      Top = 140
      Width = 580
      Height = 90
      Anchors = [akLeft, akTop, akRight]
      BevelOuter = bvNone
      TabOrder = 3
      Visible = False
      DesignSize = (
        580
        90)
      object LabelErreurSaisie: TLabel
        Left = 0
        Top = 38
        Width = 580
        Height = 20
        Anchors = [akLeft, akTop, akRight]
        AutoSize = False
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clRed
        Font.Height = -19
        Font.Name = 'Segoe UI'
        Font.Style = []
        ParentFont = False
        WordWrap = True
      end
      object EditSaisie: TEdit
        Left = 0
        Top = 0
        Width = 220
        Height = 33
        TabOrder = 0
      end
      object ComboSaisie: TComboBox
        Left = 0
        Top = 0
        Width = 220
        Height = 33
        Style = csDropDownList
        TabOrder = 1
        Visible = False
      end
      object BoutonValiderSaisie: TButton
        Left = 228
        Top = 0
        Width = 110
        Height = 30
        Caption = 'Valider'
        Default = True
        TabOrder = 2
        OnClick = GererClicValiderSaisie
      end
    end
  end
end
