// Añadir este código a tu archivo currency.dart o crear un nuevo archivo

class CurrencyFlags {
  // Mapeo entre códigos de moneda y códigos de país (ISO 3166-1 alpha-2)
  static const Map<String, String> currencyToCountryCode = {
    'AED': 'AE', // Emiratos Árabes Unidos
    'AFN': 'AF', // Afganistán
    'ALL': 'AL', // Albania
    'AMD': 'AM', // Armenia
    'ANG': 'AN', // Antillas Neerlandesas (SX para Sint Maarten)
    'AOA': 'AO', // Angola
    'ARS': 'AR', // Argentina
    'AUD': 'AU', // Australia
    'AWG': 'AW', // Aruba
    'AZN': 'AZ', // Azerbaiyán
    'BAM': 'BA', // Bosnia y Herzegovina
    'BBD': 'BB', // Barbados
    'BDT': 'BD', // Bangladesh
    'BGN': 'BG', // Bulgaria
    'BHD': 'BH', // Baréin
    'BIF': 'BI', // Burundi
    'BMD': 'BM', // Bermudas
    'BND': 'BN', // Brunéi
    'BOB': 'BO', // Bolivia
    'BRL': 'BR', // Brasil
    'BSD': 'BS', // Bahamas
    'BTC': 'BT', // Bitcoin - No tiene bandera oficial, usamos Bután
    'BTN': 'BT', // Bután
    'BWP': 'BW', // Botsuana
    'BYN': 'BY', // Bielorrusia
    'BZD': 'BZ', // Belice
    'CAD': 'CA', // Canadá
    'CDF': 'CD', // República Democrática del Congo
    'CHF': 'CH', // Suiza
    'CLF': 'CL', // Chile (Unidad de Fomento)
    'CLP': 'CL', // Chile
    'CNH': 'CN', // China (offshore)
    'CNY': 'CN', // China
    'COP': 'CO', // Colombia
    'CRC': 'CR', // Costa Rica
    'CUC': 'CU', // Cuba (convertible)
    'CUP': 'CU', // Cuba
    'CVE': 'CV', // Cabo Verde
    'CZK': 'CZ', // República Checa
    'DJF': 'DJ', // Yibuti
    'DKK': 'DK', // Dinamarca
    'DOP': 'DO', // República Dominicana
    'DZD': 'DZ', // Argelia
    'EGP': 'EG', // Egipto
    'ERN': 'ER', // Eritrea
    'ETB': 'ET', // Etiopía
    'EUR': 'EU', // Unión Europea
    'FJD': 'FJ', // Fiyi
    'FKP': 'FK', // Islas Malvinas
    'GBP': 'GB', // Reino Unido
    'GEL': 'GE', // Georgia
    'GGP': 'GG', // Guernsey
    'GHS': 'GH', // Ghana
    'GIP': 'GI', // Gibraltar
    'GMD': 'GM', // Gambia
    'GNF': 'GN', // Guinea
    'GTQ': 'GT', // Guatemala
    'GYD': 'GY', // Guyana
    'HKD': 'HK', // Hong Kong
    'HNL': 'HN', // Honduras
    'HRK': 'HR', // Croacia
    'HTG': 'HT', // Haití
    'HUF': 'HU', // Hungría
    'IDR': 'ID', // Indonesia
    'ILS': 'IL', // Israel
    'IMP': 'IM', // Isla de Man
    'INR': 'IN', // India
    'IQD': 'IQ', // Irak
    'IRR': 'IR', // Irán
    'ISK': 'IS', // Islandia
    'JEP': 'JE', // Jersey
    'JMD': 'JM', // Jamaica
    'JOD': 'JO', // Jordania
    'JPY': 'JP', // Japón
    'KES': 'KE', // Kenia
    'KGS': 'KG', // Kirguistán
    'KHR': 'KH', // Camboya
    'KMF': 'KM', // Comoras
    'KPW': 'KP', // Corea del Norte
    'KRW': 'KR', // Corea del Sur
    'KWD': 'KW', // Kuwait
    'KYD': 'KY', // Islas Caimán
    'KZT': 'KZ', // Kazajistán
    'LAK': 'LA', // Laos
    'LBP': 'LB', // Líbano
    'LKR': 'LK', // Sri Lanka
    'LRD': 'LR', // Liberia
    'LSL': 'LS', // Lesoto
    'LYD': 'LY', // Libia
    'MAD': 'MA', // Marruecos
    'MDL': 'MD', // Moldavia
    'MGA': 'MG', // Madagascar
    'MKD': 'MK', // Macedonia del Norte
    'MMK': 'MM', // Myanmar (Birmania)
    'MNT': 'MN', // Mongolia
    'MOP': 'MO', // Macao
    'MRO': 'MR', // Mauritania (antiguo)
    'MRU': 'MR', // Mauritania
    'MUR': 'MU', // Mauricio
    'MVR': 'MV', // Maldivas
    'MWK': 'MW', // Malaui
    'MXN': 'MX', // México
    'MYR': 'MY', // Malasia
    'MZN': 'MZ', // Mozambique
    'NAD': 'NA', // Namibia
    'NGN': 'NG', // Nigeria
    'NIO': 'NI', // Nicaragua
    'NOK': 'NO', // Noruega
    'NPR': 'NP', // Nepal
    'NZD': 'NZ', // Nueva Zelanda
    'OMR': 'OM', // Omán
    'PAB': 'PA', // Panamá
    'PEN': 'PE', // Perú
    'PGK': 'PG', // Papúa Nueva Guinea
    'PHP': 'PH', // Filipinas
    'PKR': 'PK', // Pakistán
    'PLN': 'PL', // Polonia
    'PYG': 'PY', // Paraguay
    'QAR': 'QA', // Catar
    'RON': 'RO', // Rumania
    'RSD': 'RS', // Serbia
    'RUB': 'RU', // Rusia
    'RWF': 'RW', // Ruanda
    'SAR': 'SA', // Arabia Saudita
    'SBD': 'SB', // Islas Salomón
    'SCR': 'SC', // Seychelles
    'SDG': 'SD', // Sudán
    'SEK': 'SE', // Suecia
    'SGD': 'SG', // Singapur
    'SHP': 'SH', // Santa Elena
    'SLL': 'SL', // Sierra Leona
    'SOS': 'SO', // Somalia
    'SRD': 'SR', // Surinam
    'SSP': 'SS', // Sudán del Sur
    'STD': 'ST', // Santo Tomé y Príncipe (antiguo)
    'STN': 'ST', // Santo Tomé y Príncipe
    'SVC': 'SV', // El Salvador
    'SYP': 'SY', // Siria
    'SZL': 'SZ', // Suazilandia/Esuatini
    'THB': 'TH', // Tailandia
    'TJS': 'TJ', // Tayikistán
    'TMT': 'TM', // Turkmenistán
    'TND': 'TN', // Túnez
    'TOP': 'TO', // Tonga
    'TRY': 'TR', // Turquía
    'TTD': 'TT', // Trinidad y Tobago
    'TWD': 'TW', // Taiwán
    'TZS': 'TZ', // Tanzania
    'UAH': 'UA', // Ucrania
    'UGX': 'UG', // Uganda
    'USD': 'US', // Estados Unidos
    'UYU': 'UY', // Uruguay
    'UZS': 'UZ', // Uzbekistán
    'VEF': 'VE', // Venezuela (antiguo)
    'VES': 'VE', // Venezuela
    'VND': 'VN', // Vietnam
    'VUV': 'VU', // Vanuatu
    'WST': 'WS', // Samoa
    'XAF': 'CF', // Franco CFA de África Central (usamos Rep. Centroafricana)
    'XAG': 'XA', // Plata (no tiene bandera, usaremos un código genérico)
    'XAU': 'XA', // Oro (no tiene bandera, usaremos un código genérico)
    'XCD': 'AG', // Dólar del Caribe Oriental (usamos Antigua y Barbuda)
    'XDR': 'UN', // Derechos Especiales de Giro (usaremos bandera ONU)
    'XOF': 'SN', // Franco CFA de África Occidental (usamos Senegal)
    'XPD': 'XA', // Paladio (no tiene bandera)
    'XPF': 'PF', // Franco CFP (usamos Polinesia Francesa)
    'XPT': 'XA', // Platino (no tiene bandera)
    'YER': 'YE', // Yemen
    'ZAR': 'ZA', // Sudáfrica
    'ZMW': 'ZM', // Zambia
    'ZWL': 'ZW', // Zimbabue
  };

  // Obtener el código de país para un código de moneda dado
  static String getCountryCode(String currencyCode) {
    return currencyToCountryCode[currencyCode] ?? 'XX'; // XX para desconocido
  }
}