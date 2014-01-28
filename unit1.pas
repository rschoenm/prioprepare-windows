unit Unit1;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, StdCtrls,
  Menus, DCPsha256, Clipbrd, ExtCtrls, ComCtrls, zipper, types, unit2;

type

  { TForm1 }

  TForm1 = class(TForm)
    Button1: TButton;
    Button2: TButton;
    Button3: TButton;
    Button4: TButton;
    Button5: TButton;
    Button6: TButton;
    Button7: TButton;
    DCP_sha256: TDCP_sha256;
    Edit1: TEdit;
    Edit2: TEdit;
    Edit3: TEdit;
    Edit4: TEdit;  // this one will contain the name of the file to be processd and there is no related control in the GUI
    Edit5: TEdit;
    GroupBox1: TGroupBox;
    GroupBox2: TGroupBox;
    Label2: TLabel;
    MainMenu1: TMainMenu;
    MenuItem1: TMenuItem;
    MenuItem10: TMenuItem;
    MenuItem11: TMenuItem;
    MenuItem12: TMenuItem;
    MenuItem2: TMenuItem;
    MenuItem3: TMenuItem;
    MenuItem4: TMenuItem;
    MenuItem5: TMenuItem;
    MenuItem6: TMenuItem;
    MenuItem7: TMenuItem;
    MenuItem8: TMenuItem;
    MenuItem9: TMenuItem;
    OpenDialog1: TOpenDialog;
    StatusBar1: TStatusBar;
    procedure Button1Click(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure Button3Click(Sender: TObject);
    procedure Button4Click(Sender: TObject);
    procedure Button5Click(Sender: TObject);
    procedure Button6Click(Sender: TObject);
    procedure Button7Click(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDropFiles(Sender: TObject; const FileNames: array of String);
    procedure MenuItem10Click(Sender: TObject);
    procedure MenuItem11Click(Sender: TObject);
    procedure MenuItem12Click(Sender: TObject);

    procedure MenuItem1Click(Sender: TObject);
    procedure MenuItem2Click(Sender: TObject);
    procedure MenuItem3Click(Sender: TObject);
    procedure MenuItem4Click(Sender: TObject);
    procedure MenuItem6Click(Sender: TObject);
    procedure MenuItem7Click(Sender: TObject);
    procedure MenuItem8Click(Sender: TObject);
    procedure MenuItem9Click(Sender: TObject);
    procedure ProcessFile(Sender: TObject; filename: String);
    procedure SaveProtocol(Sender: TObject; filename: string);
    procedure SaveArchiv(Sender: TObject; filename: string);
  private
    { private declarations }
  public
    { public declarations }
  end;

var
  Form1: TForm1;

implementation

{$R *.lfm}

//-----------------------------------
//------- own functions ---------
//-----------------------------------




function SHA256(const aStr: String): String;
var
  hasher: TDCP_sha256;
  digest: array [0..31] of Byte = (0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0); // 256 bit -> 32 byte
  i: Integer;
begin
  hasher := TDCP_sha256.Create(nil);
  try
    hasher.Init;
    hasher.UpdateStr(aStr);
    hasher.Final(digest);
    Result := '';
    for i := Low(digest) to High(digest) do
      Result := Result+IntToHex(digest[i], 2);
  finally
    hasher.Free;
  end;
end;

function RightStr(const Str: string; Size: Word): string;
//----------------------------------------------------
// Returns sub-string of length size from the right
var
   len: LongInt;
begin
     len := Length(str);
     if Size > len then Size := len;
     RightStr := Copy(Str, len - Size + 1, Size)
end {RightStr};

//----------------------------------------------------

function LeftStr(const Str: string; Size: Word): string;
//----------------------------------------------------
// Returns sub-string of length size from the left

begin
     LeftStr := Copy(Str, 1, Size)
end {LeftStr};

//----------------------------------------------------

function MidStr(const strString: string; n, size: integer): string;
//----------------------------------------------------
// returns sub-string from position n and of length size

var
   strStr: string;
begin
     strStr := Copy(strString, n, size);
     Result := strStr;
end {MidStr};

//----------------------------------------------------

function Instr(const strSource: string; const strSubStr: string): Integer;
//----------------------------------------------------

begin
     // searchs for postion of sub-string in string

   Result := Pos(strSubstr, strSource);
end {InStr};

//----------------------------------------------------

function RInstr(const Str: string; const strSuche: string): Integer;
//----------------------------------------------------
var
   i: integer;
   l: integer;
begin
     // Instr from the right
     i := 0;
     l := Length(strsuche);
     for i := length(Str) downto 1 do
     begin
          if midStr(Str, i, l) = strSuche then
          begin
               Break;
          end;
     end;
     Result := i;
end;

function CheckStr(const aStr: String):string;
var i, j : Integer;
    r : string;
    s : Integer;
    c : string;
    t : Integer;
    u : string;
    b : boolean;
begin
  b :=true;
  s := 0;

  //------------- allowed chars ----------------------
  c := 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789.- ';

  for i := 1 to Length(aStr) do
   begin
        t := 0;
        for j := 1 to Length(c) do
         begin
              if aStr[i] = c[j] then
                 begin
                      inc(s);
                      inc(t);
                 end;

         end;
        if (t = 0) and b then
          begin
           b := false;
           u := MidStr(UTF8toAnsi(aStr), i, 1);
           // ShowMessage ('string: '+AnsitoUTF8(u));
          end;

   end;

   r := AnsitoUTF8(u);

   if s = Length(aStr) then
      r := '0';

   CheckStr := r;
end;



//----------------------------------------------------

procedure TForm1.SaveProtocol(Sender: TObject; filename: string);
var
   Target: TFileStream;
   s : string;
   t : string;
   newFilename : string;
   do_save: Boolean;
   filename_ansi:string;
begin
    Target:= nil;

    filename_ansi := UTF8toAnsi(filename);

    do_save := true;

    StatusBar1.SimpleText := '';

    t := ChangeFileExt(filename_ansi,'_prio.txt');
    newFilename := ExtractFilePath(filename_ansi) + ExtractFileName(t);

    if FileExists(newFilename) then
      begin
          if MessageDlg('Prioprepare', 'protocol "'+ExtractFileName(t)+'" exists already. Overwrite?',mtWarning,[mbNo, mbYes],0) = mrNo then
             begin
                  do_save := false;
             end;
      end;


 if do_save then
  begin
    try
      Target:= TFileStream.Create(newFilename,fmCreate);
      if Target <> nil then
        begin
         s := 'Date: ';
         Target.WriteBuffer(Pointer(s)^,length(s));
         Target.WriteByte(13);
         Target.WriteByte(10);

         s := FormatDateTime('DD.MM.YYYY hh:nn:ss',Now);
         Target.WriteBuffer(Pointer(s)^,length(s));
         Target.WriteByte(13);
         Target.WriteByte(10);
         Target.WriteByte(13);
         Target.WriteByte(10);

         s := 'File: ';
         Target.WriteBuffer(Pointer(s)^,length(s));
         Target.WriteByte(13);
         Target.WriteByte(10);
         s := ExtractFileName(filename);
         Target.WriteBuffer(Pointer(s)^,length(s));
         Target.WriteByte(13);
         Target.WriteByte(10);
         Target.WriteByte(13);
         Target.WriteByte(10);

         s := 'Path: ';
         Target.WriteBuffer(Pointer(s)^,length(s));
         Target.WriteByte(13);
         Target.WriteByte(10);
         s := ExtractFilePath(filename);
         Target.WriteBuffer(Pointer(s)^,length(s));
         Target.WriteByte(13);
         Target.WriteByte(10);
         Target.WriteByte(13);
         Target.WriteByte(10);

         s := 'SHA256: ';
         Target.WriteBuffer(Pointer(s)^,length(s));
         Target.WriteByte(13);
         Target.WriteByte(10);
         s := RightStr(Edit1.text,16) + Edit2.text + LeftStr(Edit3.text,13); // get hash value from Edit fields
         Target.WriteBuffer(Pointer(s)^,length(s));
         Target.WriteByte(13);
         Target.WriteByte(10);

         FreeAndNil(Target);

         StatusBar1.SimpleText := 'Protocol saved to "'+ ExtractFileName(t)+ '"';

          //Label2.Caption := newFilename;
          end;
         except
           MessageDlg('Unable to save file',mtError,[mbOK],0);
      end;
    end;
end;

procedure TForm1.SaveArchiv(Sender: TObject; filename: string);
var
  t : string;
  p : string;
  s : string;
  do_save : Boolean;

  OurZipper: TZipper;
  Target : TMemoryStream;
  filename_ansi : string;

begin

  filename_ansi := UTF8toAnsi(filename);

  OurZipper := NIL;
  StatusBar1.SimpleText := '';
  t := ChangeFileExt(filename_ansi,'_prio.zip');
  p := ChangeFileExt(filename,'_prio.txt');

  do_save := true;

  if FileExistsUTF8(AnsitoUTF8(t)) then
      begin
          if MessageDlg('Prioprepare', 'Archive "'+ExtractFileName(t)+'" exists already. Overwrite?',mtWarning,[mbNo, mbYes],0) = mrNo then
             begin
                  do_save := false;
             end;
      end;

 if do_save then
 begin

  Target := TMemoryStream.Create;

  s := 'Date: ';
  Target.WriteBuffer(Pointer(s)^,length(s));
  Target.WriteByte(13);
  Target.WriteByte(10);

  s := FormatDateTime('DD.MM.YYYY hh:nn:ss',Now);
  Target.WriteBuffer(Pointer(s)^,length(s));
  Target.WriteByte(13);
  Target.WriteByte(10);
  Target.WriteByte(13);
  Target.WriteByte(10);

  s := 'File: ';
  Target.WriteBuffer(Pointer(s)^,length(s));
  Target.WriteByte(13);
  Target.WriteByte(10);
  s := ExtractFileName(filename);
  Target.WriteBuffer(Pointer(s)^,length(s));
  Target.WriteByte(13);
  Target.WriteByte(10);
  Target.WriteByte(13);
  Target.WriteByte(10);

  s := 'Path: ';
  Target.WriteBuffer(Pointer(s)^,length(s));
  Target.WriteByte(13);
  Target.WriteByte(10);
  s := ExtractFilePath(filename);
  Target.WriteBuffer(Pointer(s)^,length(s));
  Target.WriteByte(13);
  Target.WriteByte(10);
  Target.WriteByte(13);
  Target.WriteByte(10);

  s := 'SHA-256: ';
  Target.WriteBuffer(Pointer(s)^,length(s));
  Target.WriteByte(13);
  Target.WriteByte(10);
  s := RightStr(Edit1.text,16) + Edit2.text + LeftStr(Edit3.text,13);  // get hash value from Edit fields
  Target.WriteBuffer(Pointer(s)^,length(s));
  Target.WriteByte(13);
  Target.WriteByte(10);

  Target.Position := 0;

  //aStream.Free;
   try
    OurZipper := TZipper.Create;
    if OurZipper <> NIL then
      begin
           OurZipper.FileName := t;
           OurZipper.Entries.AddFileEntry(filename_ansi, UTF8toAnsi(ExtractFileName(UTF8toAnsi(filename))));
           //OurZipper.Entries.AddFileEntry(p, ExtractFileName(p));
           OurZipper.Entries.AddFileEntry(Target, ExtractFileName(p));
           OurZipper.ZipAllFiles;
           OurZipper.Free;
           StatusBar1.SimpleText := 'Archive saved to "'+ ExtractFileName(AnsitoUTF8(t))+ '"';
      end;
    except
      MessageDlg('Unable to save file',mtError,[mbOK],0);
    end;
  FreeAndNil(Target);
 end;
end;

procedure TForm1.ProcessFile(Sender: TObject; filename: string);
var
   Hash: TDCP_sha256;
   Digest: array[0..31] of byte = (0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0);  // SHA256
   Source: TFileStream;
   i: integer;
   s: string;
   t: string;
   r: string;
   filename_ansi : string;
begin

   filename_ansi := UTF8toAnsi(filename);

    Edit4.Text := '';

    Label2.Caption := '';
    Edit1.Text := '';
    Edit2.Text := '';
    Edit3.Text := '';
    Edit5.Text := '';
    StatusBar1.SimpleText := 'No File loaded';

    Button1.Enabled := False;
    Button2.Enabled := False;
    Button3.Enabled := False;
    Button6.Enabled := False;
    Button7.Enabled := False;

    MenuItem6.Enabled:= False;
    MenuItem7.Enabled:= False;
    MenuItem8.Enabled:= False;
    MenuItem9.Enabled:= False;
    MenuItem12.Enabled:= False;

    Button4.Enabled := False;
    Button5.Enabled := False;
    MenuItem10.Enabled:= False;
    MenuItem11.Enabled:= False;

    Form1.Update;

    r := CheckStr(ExtractFileName(filename));

    if r <> '0' then
     begin
        ShowMessage ('The file name contains the character "'+r+'", that is not suitable for the text of a bank transaction.'+char(13)+char(13)+'Please use for the file name only'+char(13)+'- characters A-Z'+char(13)+'- numeric characters 0-9'+char(13)+'- dot (.) and minus (-)');
        exit;
     end;

    if FileExists(filename_ansi) then
      begin
        Source:= nil;

        Edit4.Text := ExtractFileName(filename);
        Label2.Caption := filename; // store full filename in invisible label
        try
          Source:= TFileStream.Create(filename_ansi,fmOpenRead);  // open the file
        except
          MessageDlg('Unable to open file.',mtError,[mbOK],0);
        end;
        if Source <> nil then
          begin
            StatusBar1.SimpleText := 'calculating SHA-256';
            Form1.Update;

            Hash:= TDCP_sha256.Create(Self);          // create the hash
            Hash.Init;                                   // initialize it
            Hash.UpdateStream(Source,Source.Size); // hash the stream contents
            Hash.Final(Digest);                          // produce the digest
            Source.Free;
            s:= '';
            for i:= 0 to 31 do
              s:= s + IntToHex(Digest[i],2);

            Edit1.Text := 'SHA-256 hash value ' + LeftStr(s,16);
            Edit2.Text := MidStr(s,17,35);
            t := MidStr(s,52,13) + ' '+ LeftStr(Edit4.Text,22);
            Edit3.Text := t;
            t := MidStr(Edit4.Text,23,35);
            Edit5.Text := t;

            Button1.Enabled := True;
            Button2.Enabled := True;
            Button3.Enabled := True;
            Button6.Enabled := True;
            Button7.Enabled := True;

            Button4.Enabled := True;
            Button5.Enabled := True;

            MenuItem6.Enabled:= True;
            MenuItem7.Enabled:= True;
            MenuItem8.Enabled:= True;
            MenuItem9.Enabled:= True;
            MenuItem12.Enabled:= True;

            MenuItem10.Enabled:= True;
            MenuItem11.Enabled:= True;
            StatusBar1.SimpleText := 'SHA-256 calculated';
         end;
      end;
end;


{ TForm1 }

procedure TForm1.FormCreate(Sender: TObject);
begin
  Form1.BorderIcons := [biSystemMenu,biMinimize];

  if FileExistsUTF8(ParamStr(1)) then
   begin
     ProcessFile(Sender,ParamStr(1));
   end;
end;

procedure TForm1.Button1Click(Sender: TObject);
begin
     Clipboard.AsText := Edit1.Text;
     StatusBar1.SimpleText := 'Copied line 1 t clipboard';

end;

procedure TForm1.Button2Click(Sender: TObject);
begin
     Clipboard.AsText := Edit2.Text;
     StatusBar1.SimpleText := 'Copied line 2 t clipboard';
end;

procedure TForm1.Button3Click(Sender: TObject);
begin
     Clipboard.AsText := Edit3.Text;
     StatusBar1.SimpleText := 'Copied line 3 t clipboard';
end;

procedure TForm1.Button4Click(Sender: TObject);
begin
  SaveProtocol(Sender,Label2.Caption);
end;

procedure TForm1.Button5Click(Sender: TObject);
begin
   SaveArchiv(Sender,Label2.Caption);
end;

procedure TForm1.Button6Click(Sender: TObject);
begin
   Clipboard.AsText := Edit5.Text;
   StatusBar1.SimpleText := 'Copied line 4 t clipboard';
end;

procedure TForm1.Button7Click(Sender: TObject);
begin
     Clipboard.AsText := Edit1.Text + Edit2.Text + Edit3.Text + Edit5.Text;; //Put text on clipboard.
     StatusBar1.SimpleText := 'Copied all to clipboard';
end;

procedure TForm1.FormDropFiles(Sender: TObject; const FileNames: array of String
  );
var filename : string;
begin
  filename := FileNames[0];
  ProcessFile(Sender,filename);
end;

procedure TForm1.MenuItem10Click(Sender: TObject);
begin
  SaveProtocol(Sender,Label2.Caption);
end;

procedure TForm1.MenuItem11Click(Sender: TObject);
begin
   SaveArchiv(Sender,Label2.Caption);
end;

procedure TForm1.MenuItem12Click(Sender: TObject);
begin
  Clipboard.AsText := Edit5.Text;
  StatusBar1.SimpleText := 'Copied line 4 t clipboard';
end;



procedure TForm1.MenuItem1Click(Sender: TObject);
begin

end;

procedure TForm1.MenuItem2Click(Sender: TObject);
var filename : string;
begin
   if OpenDialog1.Execute then
      begin
        filename := OpenDialog1.Filename;
        ProcessFile(Sender,filename);
      end;
end;

procedure TForm1.MenuItem3Click(Sender: TObject);
begin

end;

procedure TForm1.MenuItem4Click(Sender: TObject);
begin
  unit2.Form2.Show;
end;

procedure TForm1.MenuItem6Click(Sender: TObject);
begin
     Clipboard.AsText := Edit1.Text + Edit2.Text + Edit3.Text + Edit5.Text;; //Put text on clipboard.
     StatusBar1.SimpleText := 'Copied all to clipboard';
end;

procedure TForm1.MenuItem7Click(Sender: TObject);
begin
   Clipboard.AsText := Edit1.Text;
   StatusBar1.SimpleText := 'Copied line 1 to clipboard';
end;

procedure TForm1.MenuItem8Click(Sender: TObject);
begin
  Clipboard.AsText := Edit2.Text;
  StatusBar1.SimpleText := 'Copied line 2 to clipboard';
end;

procedure TForm1.MenuItem9Click(Sender: TObject);
begin
  Clipboard.AsText := Edit3.Text;
  StatusBar1.SimpleText := 'Copied line 3 to clipboard';
end;



end.

