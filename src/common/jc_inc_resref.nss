/*******************************************************************************
 * @file common/jc_inc_resref.nss
 * Utilities for working with Resource Reference (ResRef) strings
 * @detail
 *   - A ResRef can contain up to 16 characters.
 *   - A ResRef does not include the file extension.
 *   - A ResRef is case insensitive. Internally, uppercase characters are
 *     converted to lowercase.
 *   - A ResRef can only contain the following characters:
 *     + Letters `abcdefghijklmnopqrstuvwxyz`
 *     + Digits `0123456789`
 *     + Underscore `_`
 *     + Plus and minus `+-`
 *******************************************************************************/

/*******************************************************************************
 * ResRef encoded with 12 bytes
 *******************************************************************************/
struct EncodedResRef {
	int x0, x1, x2, x3, x4, x5, x6, x7, x8, x9, xA, xB;
};

string RESREF_Decode(struct EncodedResRef e);
struct EncodedResRef RESREF_Encode(string s);
struct EncodedResRef RESREF_GetGlobal(string sPrefix);
int RESREF_HexToInt(string s);
string RESREF_IntToHex(int n);
string RESREF_PadLeft(string s, int nMinLength, string c);
string RESREF_PadRight(string s, int nMinLength, string c);
void RESREF_SetGlobal(string sPrefix, struct EncodedResRef e);

int resref_ByteToVariable(int n);
string resref_Decode4Characters(int n);
string resref_DecodeCharacter(int n);
int resref_Encode4Characters(string s);
int resref_EncodeCharacter(string c);
int resref_VariableToByte(int n);

/*******************************************************************************
 * Decodes a ResRef struct
 * @param e EncodedResRef struct
 * @return ResRef string
 ******************************************************************************/
string RESREF_Decode(struct EncodedResRef e) {
	return resref_Decode4Characters(e.x0 << 16 | e.x1 << 8 | e.x2)
		 + resref_Decode4Characters(e.x3 << 16 | e.x4 << 8 | e.x5)
		 + resref_Decode4Characters(e.x6 << 16 | e.x7 << 8 | e.x8)
		 + resref_Decode4Characters(e.x9 << 16 | e.xA << 8 | e.xB);
}

/*******************************************************************************
 * Encodes a ResRef in a struct
 * @param s ResRef
 * @return EncodedResRef struct
 ******************************************************************************/
struct EncodedResRef RESREF_Encode(string s) {
	s = RESREF_PadRight(s, 16, "=");
	struct EncodedResRef e;
	int n = resref_Encode4Characters(GetSubString(s, 0, 4));
	e.x0 = (n & 0x00FF0000) >> 16;
	e.x1 = (n & 0x0000FF00) >> 8;
	e.x2 = (n & 0x000000FF);
	n = resref_Encode4Characters(GetSubString(s, 4, 4));
	e.x3 = (n & 0x00FF0000) >> 16;
	e.x4 = (n & 0x0000FF00) >> 8;
	e.x5 = (n & 0x000000FF);
	n = resref_Encode4Characters(GetSubString(s, 8, 4));
	e.x6 = (n & 0x00FF0000) >> 16;
	e.x7 = (n & 0x0000FF00) >> 8;
	e.x8 = (n & 0x000000FF);
	n = resref_Encode4Characters(GetSubString(s, 12, 4));
	e.x9 = (n & 0x00FF0000) >> 16;
	e.xA = (n & 0x0000FF00) >> 8;
	e.xB = (n & 0x000000FF);
	return e;
}

/*******************************************************************************
 * Reads an encoded ResRef from 12 global numbers
 * @detail
 *   The name of each global number is the specified prefix appended with a
 *   hexadecimal character 0-B.
 * @param sPrefix global number prefix
 * @return EncodedResRef struct
 ******************************************************************************/
struct EncodedResRef RESREF_GetGlobal(string sPrefix) {
	struct EncodedResRef e;
	e.x0 = resref_VariableToByte(GetGlobalNumber(sPrefix + "0"));
	e.x1 = resref_VariableToByte(GetGlobalNumber(sPrefix + "1"));
	e.x2 = resref_VariableToByte(GetGlobalNumber(sPrefix + "2"));
	e.x3 = resref_VariableToByte(GetGlobalNumber(sPrefix + "3"));
	e.x4 = resref_VariableToByte(GetGlobalNumber(sPrefix + "4"));
	e.x5 = resref_VariableToByte(GetGlobalNumber(sPrefix + "5"));
	e.x6 = resref_VariableToByte(GetGlobalNumber(sPrefix + "6"));
	e.x7 = resref_VariableToByte(GetGlobalNumber(sPrefix + "7"));
	e.x8 = resref_VariableToByte(GetGlobalNumber(sPrefix + "8"));
	e.x9 = resref_VariableToByte(GetGlobalNumber(sPrefix + "9"));
	e.xA = resref_VariableToByte(GetGlobalNumber(sPrefix + "A"));
	e.xB = resref_VariableToByte(GetGlobalNumber(sPrefix + "B"));
	return e;
}

/*******************************************************************************
 * Converts a hexadecimal string to the corresponding integer value
 * @param s hexadecimal string
 * @return integer value
 ******************************************************************************/
int RESREF_HexToInt(string s) {
	int nLength = GetStringLength(s);
	int n = 0;
	string c;
	int x;
	int i;
	for (i = 0; i < nLength; ++i) {
		c = GetSubString(s, i, 1);
		if (c == "f" || c == "F") {
			x = 0x0000000F;
		}
		else if (c == "e" || c == "E") {
			x = 0x0000000E;
		}
		else if (c == "d" || c == "D") {
			x = 0x0000000D;
		}
		else if (c == "c" || c == "C") {
			x = 0x0000000C;
		}
		else if (c == "b" || c == "B") {
			x = 0x0000000B;
		}
		else if (c == "a" || c == "A") {
			x = 0x0000000A;
		}
		else {
			x = StringToInt(c);
		}
		n |= x << (4 * (nLength - i - 1));
	}
	return n;
}

/*******************************************************************************
 * Converts a hexadecimal string to the corresponding integer value
 * @param n integer value
 * @return hexadecimal string
 ******************************************************************************/
string RESREF_IntToHex(int n) {
	string s = "";
	int x;
	while (n) {
		x = n & 0x0000000F;
		if (x < 10) {
			s = IntToString(x) + s;
		}
		else if (x == 0x0000000A) {
			s = "a" + s;
		}
		else if (x == 0x0000000B) {
			s = "b" + s;
		}
		else if (x == 0x0000000C) {
			s = "c" + s;
		}
		else if (x == 0x0000000D) {
			s = "d" + s;
		}
		else if (x == 0x0000000E) {
			s = "e" + s;
		}
		else if (x == 0x0000000F) {
			s = "f" + s;
		}
		else {
			s = "0" + s;
		}
		n >>= 4;
	}
	return s;
}

/*******************************************************************************
 * Prepends a padding character to a string to reach a minimum length
 * @param s string
 * @param nMinLength minimum string length
 * @param c padding character
 * @return string with length of at least nMinLength
 ******************************************************************************/
string RESREF_PadLeft(string s, int nMinLength, string c) {
	int nLength = GetStringLength(s);
	int i;
	for (i = 0; i < nMinLength - nLength; ++i) {
		s = c + s;
	}
	return s;
}

/*******************************************************************************
 * Appends a padding character to a string to reach a minimum length
 * @param s string
 * @param nMinLength minimum string length
 * @param c padding character
 * @return string with length of at least nMinLength
 ******************************************************************************/
string RESREF_PadRight(string s, int nMinLength, string c) {
	int nLength = GetStringLength(s);
	int i;
	for (i = 0; i < nMinLength - nLength; ++i) {
		s += c;
	}
	return s;
}

/*******************************************************************************
 * Stores an encoded ResRef using 12 global numbers
 * @detail
 *   The name of each global number is the specified prefix appended with a
 *   hexadecimal character 0-B.
 * @param sPrefix global number prefix
 * @param e encoded ResRef
 ******************************************************************************/
void RESREF_SetGlobal(string sPrefix, struct EncodedResRef e) {
	SetGlobalNumber(sPrefix + "0", resref_ByteToVariable(e.x0));
	SetGlobalNumber(sPrefix + "1", resref_ByteToVariable(e.x1));
	SetGlobalNumber(sPrefix + "2", resref_ByteToVariable(e.x2));
	SetGlobalNumber(sPrefix + "3", resref_ByteToVariable(e.x3));
	SetGlobalNumber(sPrefix + "4", resref_ByteToVariable(e.x4));
	SetGlobalNumber(sPrefix + "5", resref_ByteToVariable(e.x5));
	SetGlobalNumber(sPrefix + "6", resref_ByteToVariable(e.x6));
	SetGlobalNumber(sPrefix + "7", resref_ByteToVariable(e.x7));
	SetGlobalNumber(sPrefix + "8", resref_ByteToVariable(e.x8));
	SetGlobalNumber(sPrefix + "9", resref_ByteToVariable(e.x9));
	SetGlobalNumber(sPrefix + "A", resref_ByteToVariable(e.xA));
	SetGlobalNumber(sPrefix + "B", resref_ByteToVariable(e.xB));
}

/*******************************************************************************
 * Converts a signed integer variable to an unsigned byte
 * @param n 1-byte signed integer value
 * @return unsigned byte
 ******************************************************************************/
int resref_ByteToVariable(int n) {
	if (n >= 128) {
		return n - 256;
	}
	return n;
}

/*******************************************************************************
 * Converts an unsigned byte to a signed integer variable
 * @param n n unsigned byte
 * @return 1-byte signed integer value
 ******************************************************************************/
int resref_VariableToByte(int n) {
	if (n < 0) {
		return n + 256;
	}
	return n;
}

/*******************************************************************************
 * Decodes 4 ResRef characters from 3 bytes
 * @param x 3-byte positive value
 * @return 4-character string
 ******************************************************************************/
string resref_Decode4Characters(int n) {
	return resref_DecodeCharacter((n & 0x00FC0000) >> 18)
		 + resref_DecodeCharacter((n & 0x0003F000) >> 12)
		 + resref_DecodeCharacter((n & 0x00000FC0) >> 6)
		 + resref_DecodeCharacter((n & 0x0000003F));
}

/*******************************************************************************
 * Converts a 6-bit encoded ResRef character to a 1-character string.
 * @detail
 *   0b001xxxxx letters
 *   0b0001xxxx digits
 *   0b0000xxxx special characters
 * @param n 6-bit positive value
 * @return 1-character string
 ******************************************************************************/
string resref_DecodeCharacter(int n) {
	if (n == 0x0000000F) {
		return "_";
	}
	if (n == 0x00000021) {
		return "a";
	}
	if (n == 0x00000022) {
		return "b";
	}
	if (n == 0x00000023) {
		return "c";
	}
	if (n == 0x00000024) {
		return "d";
	}
	if (n == 0x00000025) {
		return "e";
	}
	if (n == 0x00000026) {
		return "f";
	}
	if (n == 0x00000027) {
		return "g";
	}
	if (n == 0x00000028) {
		return "h";
	}
	if (n == 0x00000029) {
		return "i";
	}
	if (n == 0x0000002A) {
		return "j";
	}
	if (n == 0x0000002B) {
		return "k";
	}
	if (n == 0x0000002C) {
		return "l";
	}
	if (n == 0x0000002D) {
		return "m";
	}
	if (n == 0x0000002E) {
		return "n";
	}
	if (n == 0x0000002F) {
		return "o";
	}
	if (n == 0x00000030) {
		return "p";
	}
	if (n == 0x00000031) {
		return "q";
	}
	if (n == 0x00000032) {
		return "r";
	}
	if (n == 0x00000033) {
		return "s";
	}
	if (n == 0x00000034) {
		return "t";
	}
	if (n == 0x00000035) {
		return "u";
	}
	if (n == 0x00000036) {
		return "v";
	}
	if (n == 0x00000037) {
		return "w";
	}
	if (n == 0x00000038) {
		return "x";
	}
	if (n == 0x00000039) {
		return "y";
	}
	if (n == 0x0000003A) {
		return "z";
	}
	if (n == 0x00000010) {
		return "0";
	}
	if (n == 0x00000011) {
		return "1";
	}
	if (n == 0x00000012) {
		return "2";
	}
	if (n == 0x00000013) {
		return "3";
	}
	if (n == 0x00000014) {
		return "4";
	}
	if (n == 0x00000015) {
		return "5";
	}
	if (n == 0x00000016) {
		return "6";
	}
	if (n == 0x00000017) {
		return "7";
	}
	if (n == 0x00000018) {
		return "8";
	}
	if (n == 0x00000019) {
		return "9";
	}
	if (n == 0x0000000B) {
		return "+";
	}
	if (n == 0x0000000D) {
		return "-";
	}
	return "";
}

/*******************************************************************************
 * Encodes 4 ResRef characters in 3 bytes
 * @param s ResRef string
 * @return 4-character string
 ******************************************************************************/
int resref_Encode4Characters(string s) {
	return (resref_EncodeCharacter(GetSubString(s, 0, 1)) << 18)
		 | (resref_EncodeCharacter(GetSubString(s, 1, 1)) << 12)
		 | (resref_EncodeCharacter(GetSubString(s, 2, 1)) << 6)
		 | (resref_EncodeCharacter(GetSubString(s, 3, 1)));
}

/*******************************************************************************
 * Encodes a ResRef character in 6 bits
 * @detail
 *   0b001xxxxx letters
 *   0b0001xxxx digits
 *   0b0000xxxx special characters
 * @param c 1-character string
 * @return 6-bit positive value
 ******************************************************************************/
int resref_EncodeCharacter(string c) {
	if (c == "_") {
		return 0x0000000F;
	}
	if (c == "0") {
		return 0x00000010;
	}
	if (c == "1") {
		return 0x00000011;
	}
	if (c == "2") {
		return 0x00000012;
	}
	if (c == "3") {
		return 0x00000013;
	}
	if (c == "4") {
		return 0x00000014;
	}
	if (c == "5") {
		return 0x00000015;
	}
	if (c == "6") {
		return 0x00000016;
	}
	if (c == "7") {
		return 0x00000017;
	}
	if (c == "8") {
		return 0x00000018;
	}
	if (c == "9") {
		return 0x00000019;
	}
	if (c == "a" || c == "A") {
		return 0x00000021;
	}
	if (c == "b" || c == "B") {
		return 0x00000022;
	}
	if (c == "c" || c == "C") {
		return 0x00000023;
	}
	if (c == "d" || c == "D") {
		return 0x00000024;
	}
	if (c == "e" || c == "E") {
		return 0x00000025;
	}
	if (c == "f" || c == "F") {
		return 0x00000026;
	}
	if (c == "g" || c == "G") {
		return 0x00000027;
	}
	if (c == "h" || c == "H") {
		return 0x00000028;
	}
	if (c == "i" || c == "I") {
		return 0x00000029;
	}
	if (c == "j" || c == "J") {
		return 0x0000002A;
	}
	if (c == "k" || c == "K") {
		return 0x0000002B;
	}
	if (c == "l" || c == "L") {
		return 0x0000002C;
	}
	if (c == "m" || c == "M") {
		return 0x0000002D;
	}
	if (c == "n" || c == "N") {
		return 0x0000002E;
	}
	if (c == "o" || c == "O") {
		return 0x0000002F;
	}
	if (c == "p" || c == "P") {
		return 0x00000030;
	}
	if (c == "q" || c == "Q") {
		return 0x00000031;
	}
	if (c == "r" || c == "R") {
		return 0x00000032;
	}
	if (c == "s" || c == "S") {
		return 0x00000033;
	}
	if (c == "t" || c == "T") {
		return 0x00000034;
	}
	if (c == "u" || c == "U") {
		return 0x00000035;
	}
	if (c == "v" || c == "V") {
		return 0x00000036;
	}
	if (c == "w" || c == "W") {
		return 0x00000037;
	}
	if (c == "x" || c == "X") {
		return 0x00000038;
	}
	if (c == "y" || c == "Y") {
		return 0x00000039;
	}
	if (c == "z" || c == "Z") {
		return 0x0000003A;
	}
	if (c == "+") {
		return 0x0000000B;
	}
	if (c == "-") {
		return 0x0000000D;
	}
	return 0;
}