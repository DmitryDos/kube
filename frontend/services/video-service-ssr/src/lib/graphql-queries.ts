export const ME_QUERY = `
  query Me {
    me {
      id
      email
      name
      created_at
    }
  }
`;

export const LOGIN_MUTATION = `
  mutation Login($input: LoginInput!) {
    login(input: $input) {
      message
      user {
        id
        email
        name
        created_at
      }
    }
  }
`;

export const REGISTER_MUTATION = `
  mutation Register($input: RegisterInput!) {
    register(input: $input) {
      message
      user {
        id
        email
        name
        created_at
      }
    }
  }
`;

export const LOGOUT_MUTATION = `
  mutation Logout {
    logout
  }
`;

export const SEARCH_QUERY = `
  query Search($query: String, $page: Int, $limit: Int, $filter: String) {
    search(query: $query, page: $page, limit: $limit, filter: $filter) {
      results {
        type
        video {
          id
          title
          description
          thumbnail_url
          duration
          user_id
          created_at
        }
        author {
          id
          name
          avatar_url
        }
      }
      total
      page
      limit
    }
  }
`;

