%TTIME32ARRAY Unit tests for arrow.array.Time32Array

% Licensed to the Apache Software Foundation (ASF) under one or more
% contributor license agreements.  See the NOTICE file distributed with
% this work for additional information regarding copyright ownership.
% The ASF licenses this file to you under the Apache License, Version
% 2.0 (the "License"); you may not use this file except in compliance
% with the License.  You may obtain a copy of the License at
%
%   http://www.apache.org/licenses/LICENSE-2.0
%
% Unless required by applicable law or agreed to in writing, software
% distributed under the License is distributed on an "AS IS" BASIS,
% WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or
% implied.  See the License for the specific language governing
% permissions and limitations under the License.

classdef tTime32Array < matlab.unittest.TestCase

    properties
        ArrowArrayConstructorFcn = @arrow.array.Time32Array.fromMATLAB
    end

    properties(TestParameter)
        Unit = {arrow.type.TimeUnit.Second, arrow.type.TimeUnit.Millisecond}
    end

    methods (Test)
        function Basic(tc)
            times = seconds(1:4);
            array = tc.ArrowArrayConstructorFcn(times);
            tc.verifyInstanceOf(array, "arrow.array.Time32Array");
        end

        function TypeIsTime32(tc)
            times = seconds(1:4);
            array = tc.ArrowArrayConstructorFcn(times);
            tc.verifyTime32Type(array.Type, arrow.type.TimeUnit.Second);
        end

        function SupportedTimeUnit(tc)
            import arrow.type.TimeUnit
            times = seconds(1:4);
            
            array = tc.ArrowArrayConstructorFcn(times, TimeUnit="Second");
            tc.verifyTime32Type(array.Type, arrow.type.TimeUnit.Second);

            array = tc.ArrowArrayConstructorFcn(times, TimeUnit=TimeUnit.Second);
            tc.verifyTime32Type(array.Type, arrow.type.TimeUnit.Second);

            array = tc.ArrowArrayConstructorFcn(times, TimeUnit="Millisecond");
            tc.verifyTime32Type(array.Type, arrow.type.TimeUnit.Millisecond);

            array = tc.ArrowArrayConstructorFcn(times, TimeUnit=TimeUnit.Millisecond);
            tc.verifyTime32Type(array.Type, arrow.type.TimeUnit.Millisecond);
        end

        function UnsupportedTimeUnitError(tc)
            % Verify arrow.array.Time32Array.fromMATLAB() errors if 
            % supplied an unsupported TimeUnit (Microsecond or Nanosecond).
            import arrow.type.TimeUnit
            times = seconds(1:4);
            fcn = @() tc.ArrowArrayConstructorFcn(times, TimeUnit="Microsecond");
            tc.verifyError(fcn, "arrow:validate:temporal:UnsupportedTime32TimeUnit");

            fcn = @() tc.ArrowArrayConstructorFcn(times, TimeUnit=TimeUnit.Microsecond);
            tc.verifyError(fcn, "arrow:validate:temporal:UnsupportedTime32TimeUnit");

            fcn = @() tc.ArrowArrayConstructorFcn(times, TimeUnit="Nanosecond");
            tc.verifyError(fcn, "arrow:validate:temporal:UnsupportedTime32TimeUnit");

            fcn = @() tc.ArrowArrayConstructorFcn(times, TimeUnit=TimeUnit.Nanosecond);
            tc.verifyError(fcn, "arrow:validate:temporal:UnsupportedTime32TimeUnit");
        end

        function TestLength(testCase)
            % Verify the Length property.

            times = duration.empty(0, 1);
            array = testCase.ArrowArrayConstructorFcn(times);
            testCase.verifyEqual(array.Length, int64(0));

            times = duration(1, 2, 3);
            array = testCase.ArrowArrayConstructorFcn(times);
            testCase.verifyEqual(array.Length, int64(1));

            times = duration(1, 2, 3) + hours(0:4);
            array = testCase.ArrowArrayConstructorFcn(times);
            testCase.verifyEqual(array.Length, int64(5));
        end

        function TestToMATLAB(testCase, Unit)
            % Verify toMATLAB() round-trips the original duration array.
            times = seconds([100 200 355 400]);
            array = testCase.ArrowArrayConstructorFcn(times, TimeUnit=Unit);
            values = toMATLAB(array);
            testCase.verifyEqual(values, times');
        end

        function TestDuration(testCase, Unit)
            % Verify duration() round-trips the original duration array.
            times = seconds([100 200 355 400]);
            array = testCase.ArrowArrayConstructorFcn(times, TimeUnit=Unit);
            values = duration(array);
            testCase.verifyEqual(values, times');
        end

        function TestValid(testCase, Unit)
            % Verify the Valid property returns the expected logical vector.
            times = seconds([100 200 NaN 355 NaN 400]);
            arrray = testCase.ArrowArrayConstructorFcn(times, TImeUnit=Unit);
            testCase.verifyEqual(arrray.Valid, [true; true; false; true; false; true]);
            testCase.verifyEqual(toMATLAB(arrray), times');
            testCase.verifyEqual(duration(arrray), times');
        end

        function InferNullsTrueNVPair(testCase, Unit)
            % Verify arrow.array.Time32Array.fromMATLAB() behaves as
            % expected when InferNulls=true is provided.

            times = seconds([1 2 NaN 4 5 NaN 7]);
            array = testCase.ArrowArrayConstructorFcn(times, InferNulls=true, TimeUnit=Unit);
            expectedValid = [true; true; false; true; true; false; true];
            testCase.verifyEqual(array.Valid, expectedValid);
            testCase.verifyEqual(toMATLAB(array), times');
            testCase.verifyEqual(duration(array), times');
        end

        function InferNullsFalseNVPair(testCase, Unit)
            % Verify arrow.array.Time32Array.fromMATLAB() behaves as
            % expected when InferNulls=false is provided.

            times = seconds([1 2 NaN 4 5 NaN 7]);
            array = testCase.ArrowArrayConstructorFcn(times, InferNulls=false, TimeUnit=Unit);
            expectedValid = true([7 1]);
            testCase.verifyEqual(array.Valid, expectedValid);

            % If NaN durations were not considered null values, then they
            % are treated like int32(0) values.
            expectedTime = times';
            expectedTime([3 6]) = 0;
            testCase.verifyEqual(toMATLAB(array), expectedTime);
            testCase.verifyEqual(duration(array), expectedTime);
        end

        function TestValidNVPair(testCase, Unit)
            % Verify arrow.array.Time32Array.fromMATLAB() accepts the Valid
            % nv-pair, and it behaves as expected.

            times = seconds([1 2 NaN 4 5 NaN 7]);
            
            % Supply the Valid name-value pair as vector of indices.
            array = testCase.ArrowArrayConstructorFcn(times, TimeUnit=Unit, Valid=[1 2 3 5]);
            testCase.verifyEqual(array.Valid, [true; true; true; false; true; false; false]);
            expectedTimes = times';
            expectedTimes(3) = 0;
            expectedTimes([4 6 7]) = NaN;
            testCase.verifyEqual(toMATLAB(array), expectedTimes);

            % Supply the Valid name-value pair as a logical scalar.
            array = testCase.ArrowArrayConstructorFcn(times, TimeUnit=Unit, Valid=false);
            testCase.verifyEqual(array.Valid, false([7 1]));
            expectedTimes(:) = NaN;
            testCase.verifyEqual(toMATLAB(array), expectedTimes);
        end

        function EmptyDurationVector(testCase)
            % Verify arrow.array.Time32Array.fromMATLAB() accepts any
            % empty-shaped duration as input.

            times = duration.empty(0, 0);
            array = testCase.ArrowArrayConstructorFcn(times);
            testCase.verifyEqual(array.Length, int64(0));
            testCase.verifyEqual(array.Valid, logical.empty(0, 1));
            testCase.verifyEqual(toMATLAB(array), duration.empty(0, 1));

            % Test with an N-Dimensional empty array
            times = duration.empty(0, 1, 0);
            array = testCase.ArrowArrayConstructorFcn(times);
            testCase.verifyEqual(array.Length, int64(0));
            testCase.verifyEqual(array.Valid, logical.empty(0, 1));
            testCase.verifyEqual(toMATLAB(array), duration.empty(0, 1));
        end

        function ErrorIfNonVector(testCase)
            % Verify arrow.array.Time32Array.fromMATLAB() throws an error
            % if the input provided is not a vector.

            times = duration(200, 45, 34) + hours(0:11);
            times = reshape(times, 2, 6);
            fcn = @() testCase.ArrowArrayConstructorFcn(times);
            testCase.verifyError(fcn, "arrow:array:InvalidShape");

            times = reshape(times, 3, 2, 2);
            fcn = @() testCase.ArrowArrayConstructorFcn(times);
            testCase.verifyError(fcn, "arrow:array:InvalidShape");
        end

        function ErrorIfNonDuration(testCase)
            % Verify arrow.array.Time32Array.fromMATLAB() throws an error
            % if not given a duration as input.

            dates = datetime(2023, 4, 6);
            fcn = @() testCase.ArrowArrayConstructorFcn(dates);
            testCase.verifyError(fcn, "arrow:array:InvalidType");

            numbers = [1; 2; 3; 4];
            fcn = @() testCase.ArrowArrayConstructorFcn(numbers);
            testCase.verifyError(fcn, "arrow:array:InvalidType");
        end
    end

    methods
        function verifyTime32Type(testCase, actual, expectedTimeUnit)
            testCase.verifyInstanceOf(actual, "arrow.type.Time32Type");
            testCase.verifyEqual(actual.ID, arrow.type.ID.Time32);
            testCase.verifyEqual(actual.TimeUnit, expectedTimeUnit);
        end
    end
end