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
  
  // Build headers for API Gateway request
  const headers: HeadersInit = {
    'Accept': 'image/*',
  };
  
  if (authToken) {
    headers['Authorization'] = `Bearer ${authToken}`;
  }
  
  try {
    const response = await fetch(`${apiBaseUrl}/api/videos/${videoId}/thumbnail`, {
      method: 'GET',
      headers,
    });
    
    if (!response.ok) {
      return NextResponse.json(
        { error: 'Failed to fetch thumbnail' },
        { status: response.status }
      );
    }
    
    // Get response body as array buffer
    const arrayBuffer = await response.arrayBuffer();
    
    // Copy response headers
    const responseHeaders = new Headers();
    const contentType = response.headers.get('content-type') || 'image/jpeg';
    const cacheControl = response.headers.get('cache-control') || 'public, max-age=31536000, immutable';
    
    responseHeaders.set('content-type', contentType);
    responseHeaders.set('cache-control', cacheControl);
    
    return new NextResponse(arrayBuffer, {
      status: response.status,
      headers: responseHeaders,
    });
  } catch (error) {
    console.error('Error proxying thumbnail:', error);
    return NextResponse.json(
      { error: 'Failed to proxy thumbnail' },
      { status: 500 }
    );
  }
}

