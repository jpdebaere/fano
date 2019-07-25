{*!
 * Fano Web Framework (https://fanoframework.github.io)
 *
 * @link      https://github.com/fanoframework/fano
 * @copyright Copyright (c) 2018 Zamrony P. Juhara
 * @license   https://github.com/fanoframework/fano/blob/master/LICENSE (MIT)
 *}

(*! ---------------------------------------------
 * implementation units for app
 * that is included in fano.pas unit
 *
 * @author Zamrony P. Juhara <zamronypj@yahoo.com>
 *-----------------------------------------------*)

AppImpl,
SimpleAppImpl,

DaemonAppImpl,

{----------------Begin FastCGI related-----------------------------}
SimpleFastCGIAppImpl,

{$IFDEF unix}
SimpleUnixFastCGIAppImpl,
{$ENDIF}

SimpleSockFastCGIAppImpl,
{---------------- End FastCGI related-----------------------------}

{----------------Begin SCGI related-----------------------------}
SimpleScgiAppImpl,
{---------------- End SCGI related-----------------------------}