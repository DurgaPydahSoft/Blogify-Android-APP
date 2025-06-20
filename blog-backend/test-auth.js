const axios = require('axios');

const BASE_URL = 'http://192.168.232.93:3000';

async function testAuth() {
  console.log('Testing Blogify Backend Authentication...\n');

  try {
    // Test 1: Check if server is running
    console.log('1. Testing server connectivity...');
    try {
      await axios.get(`${BASE_URL}/api/auth/me`);
    } catch (error) {
      if (error.response && error.response.status === 401) {
        console.log('✅ Server is running (401 expected - no token provided)');
      } else {
        console.log('❌ Server connectivity issue:', error.message);
        return;
      }
    }

    // Test 2: Create a test user
    console.log('\n2. Testing user signup...');
    const testUser = {
      name: 'Test User',
      email: `test${Date.now()}@example.com`,
      password: 'password123'
    };

    let signupResponse;
    try {
      signupResponse = await axios.post(`${BASE_URL}/api/auth/signup`, testUser);
      console.log('✅ User signup successful');
      console.log('   User ID:', signupResponse.data.user.id);
    } catch (error) {
      if (error.response && error.response.status === 400 && error.response.data.message.includes('already exists')) {
        console.log('✅ User already exists (using existing user)');
        // Try to login instead
        const loginResponse = await axios.post(`${BASE_URL}/api/auth/login`, {
          email: testUser.email,
          password: testUser.password
        });
        signupResponse = loginResponse;
      } else {
        console.log('❌ Signup failed:', error.response?.data?.message || error.message);
        return;
      }
    }

    const token = signupResponse.data.token;
    console.log('   Token received:', token ? 'Yes' : 'No');

    // Test 3: Test authenticated endpoint
    console.log('\n3. Testing authenticated endpoint...');
    try {
      const meResponse = await axios.get(`${BASE_URL}/api/auth/me`, {
        headers: { 'Authorization': `Bearer ${token}` }
      });
      console.log('✅ Authentication successful');
      console.log('   User name:', meResponse.data.name);
      console.log('   User email:', meResponse.data.email);
    } catch (error) {
      console.log('❌ Authentication failed:', error.response?.data?.message || error.message);
      return;
    }

    // Test 4: Test blog creation
    console.log('\n4. Testing blog creation...');
    const testBlog = {
      title: 'Test Blog Post',
      description: 'This is a test blog post to verify the API is working.',
      categories: ['test'],
      tags: ['test', 'api'],
      isPublished: true
    };

    try {
      const blogResponse = await axios.post(`${BASE_URL}/api/blogs`, testBlog, {
        headers: { 
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${token}` 
        }
      });
      console.log('✅ Blog creation successful');
      console.log('   Blog ID:', blogResponse.data._id);
      console.log('   Blog title:', blogResponse.data.title);
    } catch (error) {
      console.log('❌ Blog creation failed:', error.response?.data?.message || error.message);
      return;
    }

    console.log('\n🎉 All tests passed! The backend is working correctly.');
    console.log('\nYou can now use the Flutter app to:');
    console.log('1. Sign up with a new account');
    console.log('2. Login with your credentials');
    console.log('3. Create, edit, and delete blogs');

  } catch (error) {
    console.log('❌ Test failed:', error.message);
  }
}

// Run the test
testAuth(); 