import { NextRequest, NextResponse } from 'next/server';
import { cookies } from 'next/headers';
import { PageParams } from '../../../../../../src/types/pageParams';

export async function GET(
  request: NextRequest,
  { params }: { params: PageParams<{ id: string }> }
) {
  const { id: videoId } = await params;
  const apiBaseUrl = process.env['NEXT_PUBLIC_API_BASE_URL'] || 'http://158.160.192.60:8080';
  
  // Get auth token from cookies
  const cookieStore = await cookies();
  const authToken = cookieStore.get('authToken')?.value;
  
  // Get Range header for video streaming
  const range = request.headers.get('range');
  
  // Build headers for API Gateway request
  const headers: HeadersInit = {
    'Accept': 'video/*',
  };
  
  if (authToken) {
    headers['Authorization'] = `Bearer ${authToken}`;
  }
  
  if (range) {
    headers['Range'] = range;
  }
  
  try {
    const response = await fetch(`${apiBaseUrl}/api/videos/${videoId}/stream/proxy`, {
      method: 'GET',
      headers,
    });
    
    if (!response.ok) {
      return NextResponse.json(
        { error: 'Failed to fetch video stream' },
        { status: response.status }
      );
    }
    
    // Get response body as stream
    const stream = response.body;
    if (!stream) {
      return NextResponse.json(
        { error: 'No stream data' },
        { status: 500 }
      );
    }
    
    // Copy response headers
    const responseHeaders = new Headers();
    const contentType = response.headers.get('content-type');
    const contentLength = response.headers.get('content-length');
    const acceptRanges = response.headers.get('accept-ranges');
    const contentRange = response.headers.get('content-range');
    
    if (contentType) responseHeaders.set('content-type', contentType);
    if (contentLength) responseHeaders.set('content-length', contentLength);
    if (acceptRanges) responseHeaders.set('accept-ranges', acceptRanges);
    if (contentRange) responseHeaders.set('content-range', contentRange);
    
    // Set CORS headers for video streaming
    responseHeaders.set('Access-Control-Allow-Origin', '*');
    responseHeaders.set('Access-Control-Allow-Methods', 'GET, HEAD, OPTIONS');
    responseHeaders.set('Access-Control-Allow-Headers', 'Range');
    responseHeaders.set('Access-Control-Expose-Headers', 'Content-Range, Content-Length, Accept-Ranges');
    
    // Return stream with proper status code (206 for partial content if range is present)
    const status = range && response.status === 206 ? 206 : response.status;
    
    return new NextResponse(stream, {
      status,
      headers: responseHeaders,
    });
  } catch (error) {
    console.error('Error proxying video stream:', error);
    return NextResponse.json(
      { error: 'Failed to proxy video stream' },
      { status: 500 }
    );
  }
}

export async function HEAD(
  _request: NextRequest,
  { params }: { params: PageParams<{ id: string }> }
) {
  const { id: videoId } = await params;
  const apiBaseUrl = process.env['NEXT_PUBLIC_API_BASE_URL'] || 'http://158.160.192.60:8080';
  
  const cookieStore = await cookies();
  const authToken = cookieStore.get('authToken')?.value;
  
  const headers: HeadersInit = {};
  if (authToken) {
    headers['Authorization'] = `Bearer ${authToken}`;
  }
  
  try {
    const response = await fetch(`${apiBaseUrl}/api/videos/${videoId}/stream/proxy`, {
      method: 'HEAD',
      headers,
    });
    
    const responseHeaders = new Headers();
    const contentType = response.headers.get('content-type');
    const contentLength = response.headers.get('content-length');
    const acceptRanges = response.headers.get('accept-ranges');
    
    if (contentType) responseHeaders.set('content-type', contentType);
    if (contentLength) responseHeaders.set('content-length', contentLength);
    if (acceptRanges) responseHeaders.set('accept-ranges', acceptRanges);
    
    return new NextResponse(null, {
      status: response.status,
      headers: responseHeaders,
    });
  } catch (error) {
    console.error('Error proxying video stream HEAD:', error);
    return NextResponse.json(
      { error: 'Failed to proxy video stream' },
      { status: 500 }
    );
  }
}

