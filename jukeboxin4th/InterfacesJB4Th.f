anew -InterfacesJB4Th.f

(( IUnknown Open-Interface
    3 0  IMethod IQueryInterface ( ppv riid -- hres )
    1 1  IMethod IAddRef ( -- refs )
    1 2  IMethod IReleaseRef (  -- refs )
  Close-Interface
 ))

IUnknown Interface IGraphBuilder {56A868A9-0AD4-11CE-B03A-0020AF0BA770}
IGraphBuilder Open-Interface
  3 3  IMethod AddFilter ( lpwstr *IBaseFilter -- hres )
  2 4  IMethod RemoveFilter ( *IBaseFilter -- hres )
  2 5  IMethod EnumFilters ( **IEnumFilters -- hres )
  3 6  IMethod FindFilterByName ( **IBaseFilter lpwstr -- hres )
  4 7  IMethod ConnectDirect ( *_AMMediaType *IPin *IPin -- hres )
  2 8  IMethod Reconnect ( *IPin -- hres )
  2 9  IMethod Disconnect ( *IPin -- hres )
  1 10  IMethod SetDefaultSyncSource ( -- hres )
  3 11  IMethod Connect ( *IPin *IPin -- hres )
  2 12  IMethod Render ( *IPin -- hres )
  3 13  IMethod RenderFile ( lpwstr lpwstr -- hres )
  4 14  IMethod AddSourceFilter ( **IBaseFilter lpwstr lpwstr -- hres )
  2 15  IMethod SetLogFile ( ULONG_PTR -- hres )
  1 16  IMethod Abort ( -- hres )
  1 17  IMethod ShouldOperationContinue ( -- hres )
  Close-Interface


IUnknown Interface IMediaEventEx {56a868c0-0ad4-11ce-b03a-0020af0ba770}
IMediaEventEx Open-Interface
  2 3  IMethod GetTypeInfoCount ( *n -- hres )
  4 4  IMethod GetTypeInfo ( **void n n -- hres )  \ IMediaEventEx_GetIDsOfNames(This,riid,rgszNames,cNames,lcid,rgDispId)
  6 5  IMethod GetIDsOfNames ( *n n n **c *GUID -- hres )
  9 6  IMethod Invoke ( *n *EXCEPINFO *variant *DISPPARAMS h n *GUID n -- hres )
  2 7  IMethod GetEventHandle ( *LONG_PTR -- hres )
  5 8  IMethod GetEvent ( n *LONG_PTR *LONG_PTR *n -- hres )
  3 9  IMethod WaitForCompletion ( *n n -- hres )
  2 10  IMethod CancelDefaultHandling ( n -- hres )
  2 11  IMethod RestoreDefaultHandling ( n -- hres )
  4 12  IMethod FreeEventParams ( LONG_PTR LONG_PTR n -- hres )
  4 13  IMethod SetNotifyWindow ( LONG_PTR n LONG_PTR -- hres )
  2 14  IMethod SetNotifyFlags ( n -- hres )
  2 15  IMethod GetNotifyFlags ( *n -- hres )
Close-Interface


IUnknown Interface IMediaControl {56A868B1-0AD4-11CE-B03A-0020AF0BA770}

IMediaControl Open-Interface
  2 3  IMethod GetTypeInfoCount ( *n -- hres )
  4 4  IMethod GetTypeInfo ( **void n n -- hres )
  6 5  IMethod GetIDsOfNames ( *n n n **c *GUID -- hres )
  9 6  IMethod Invoke ( *n *EXCEPINFO *variant *DISPPARAMS h n *GUID n -- hres )
  1 7  IMethod Run ( -- hres )
  1 8  IMethod Pause ( -- hres )
  1 9  IMethod Stop ( -- hres )
  3 10  IMethod GetState ( *n n -- hres )
  2 11  IMethod RenderFile ( bstr -- hres )
  3 12  IMethod AddSourceFilter ( *IDispatch bstr -- hres )
  2 13  IMethod GetFilterCollection ( *IDispatch -- hres )
  2 14  IMethod GetRegFilterCollection ( *IDispatch -- hres )
  1 15  IMethod StopWhenReady ( -- hres )
Close-Interface


IUnknown Interface IMediaSeeking {36b73880-c2c8-11cf-8b46-00805f6cef60}
IMediaSeeking Open-Interface
  2 3  IMethod GetCapabilities ( *n -- hres )
  2 4  IMethod CheckCapabilities ( *n -- hres )
  2 5  IMethod IsFormatSupported ( *GUID -- hres )
  2 6  IMethod QueryPreferredFormat ( *GUID -- hres )
  2 7  IMethod GetTimeFormat ( *GUID -- hres )
  2 8  IMethod IsUsingTimeFormat ( *GUID -- hres )
  2 9  IMethod SetTimeFormat ( *GUID -- hres )
  2 10  IMethod GetDuration ( *d -- hres )
  2 11  IMethod GetStopPosition ( *d -- hres )
  2 12  IMethod GetCurrentPosition ( *d -- hres )
  6 13  IMethod ConvertTimeFormat ( *GUID d *GUID *d -- hres )
  5 14  IMethod SetPositions ( n *d n *d -- hres )
  3 15  IMethod GetPositions ( *d *d -- hres )
  3 16  IMethod GetAvailable ( *d *d -- hres )
  3 17  IMethod SetRate ( f64 -- hres )
  2 18  IMethod GetRate ( *f64 -- hres )
  2 19  IMethod GetPreroll ( *d -- hres )
Close-Interface


IUnknown Interface IBaseFilter {56A86895-0AD4-11CE-B03A-0020AF0BA770}
IBaseFilter Open-Interface
  2 3  IMethod GetClassID ( *GUID -- hres )
  1 4  IMethod Stop ( -- hres )
  1 5  IMethod Pause ( -- hres )
  3 6  IMethod Run ( d -- hres )
  3 7  IMethod GetState ( *_FilterState n -- hres )
  2 8  IMethod SetSyncSource ( *IReferenceClock -- hres )
  2 9  IMethod GetSyncSource ( **IReferenceClock -- hres )
  2 10  IMethod EnumPins ( **IEnumPins -- hres )
  3 11  IMethod FindPin ( **IPin lpwstr -- hres )
  2 12  IMethod QueryFilterInfo ( *_FilterInfo -- hres )
  3 13  IMethod JoinFilterGraph ( lpwstr *IFilterGraph -- hres )
  2 14  IMethod QueryVendorInfo ( *lpwstr -- hres )
Close-Interface


IUnknown Interface IFileSourceFilter {56a868a6-0ad4-11ce-b03a-0020af0ba770}
IFileSourceFilter Open-Interface
  3 3 IMethod Load  ( pszFileName  pmt -- hres ) \ Loads the source filter with the file.
  3 4 IMethod GetCurFile  ( pszFileName pmt -- hres ) \ Retrieves the current file.
Close-Interface

\s
