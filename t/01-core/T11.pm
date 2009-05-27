package T11;
use Object::Simple;

sub bool :  Attr{ type =>    'Bool'       }
sub undef :  Attr{ type =>    'Undef'      }
sub defined :  Attr{ type =>    'Defined'    }
sub value :  Attr{ type =>    'Value'      }
sub num :  Attr{ type =>    'Num'        }
sub int :  Attr{ type =>    'Int'        }
sub str :  Attr{ type =>    'Str'        }
sub class_name : Attr{ type =>    'ClassName'  }
sub ref : Attr{ type =>    'Ref'        }
sub scalar_ref : Attr{ type =>    'ScalarRef'  }
sub array_ref : Attr{ type =>    'ArrayRef'   }
sub hash_ref : Attr{ type =>    'HashRef'    }
sub code_ref : Attr{ type =>    'CodeRef'    }
sub regexp_ref : Attr{ type =>    'RegexpRef'  }
sub glob_ref : Attr{ type =>    'GlobRef'    }
sub file_handle : Attr{ type =>    'FileHandle' }
sub object : Attr{ type =>    'Object'     }

sub class : Attr { type => 'IO::File' }

sub manual : Attr { type => sub{ $_[0] == 5 } }

Object::Simple->end;